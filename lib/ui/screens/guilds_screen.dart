import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/translations.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../services/server_service.dart';
import 'account_link_screen.dart';
import 'guild_leaderboard_screen.dart';

class GuildsScreen extends ConsumerStatefulWidget {
  const GuildsScreen({super.key});

  @override
  ConsumerState<GuildsScreen> createState() => _GuildsScreenState();
}

class _GuildsScreenState extends ConsumerState<GuildsScreen>
    with SingleTickerProviderStateMixin {
  Translations get t => ref.read(translationsProvider);
  late TabController _tabController;
  late TextEditingController _chatController;
  final ScrollController _chatScrollController = ScrollController();
  bool _loading = true;
  int _guildDetailTab = 3; // 0=members, 1=quests, 2=logs, 3=chat (chat par défaut)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chatController = TextEditingController();
    _loadGuilds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGuilds() async {
    setState(() => _loading = true);
    await ref.read(gameProvider.notifier).loadMyGuilds();
    await ref.read(gameProvider.notifier).loadAvailableGuilds();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final myGuilds = gameState.myGuilds;
    final currentGuild = gameState.currentGuild;
    final linked = gameState.isAccountLinked;
    final serverStatus = ref.watch(serverStatusProvider);

    Color statusColor(ServerStatus s) {
      switch (s) {
        case ServerStatus.connected:
          return Colors.green;
        case ServerStatus.warning:
          return Colors.orange;
        case ServerStatus.disconnected:
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    String statusLabel(ServerStatus s) {
      switch (s) {
        case ServerStatus.connected:
          return t.statusConnected;
        case ServerStatus.warning:
          return t.statusWarning;
        case ServerStatus.disconnected:
          return t.statusDisconnected;
        default:
          return '...';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(t.guilds),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor(serverStatus).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor(serverStatus), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor(serverStatus),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusLabel(serverStatus),
                    style: TextStyle(
                      color: statusColor(serverStatus),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGuilds,
          ),
        ],
        bottom: currentGuild == null
            ? TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: t.myGuilds),
                  Tab(text: t.find),
                  Tab(text: t.create),
                ],
              )
            : null,
      ),
      body: currentGuild != null
          ? _buildGuildDetail(context, ref, currentGuild, gameState)
          : Column(
              children: [
                if (!linked)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.orange.shade700,
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.accountRequiredGuild,
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const AccountLinkScreen(),
                              ));
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.orange.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            child: const Text('Lier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Opacity(
                          opacity: linked ? 1.0 : 0.4,
                          child: AbsorbPointer(
                            absorbing: !linked,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildMyGuildsTab(ref, myGuilds),
                                _buildBrowseTab(ref, gameState.availableGuilds),
                                _buildCreateTab(context, ref),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildMyGuildsTab(WidgetRef ref, List<Guild> myGuilds) {
    if (myGuilds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Vous n\'êtes dans aucune guilde',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              t.joinOrCreateGuild,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(gameProvider.notifier).loadMyGuilds(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myGuilds.length,
        itemBuilder: (context, index) {
          final g = myGuilds[index];
          final myRole = g.myRole ?? 'member';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                ref.read(gameProvider.notifier).selectGuild(g.id);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      child: Text(
                        g.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            '${g.memberCount}/${g.maxMembers} ${t.membersWord} • ${_roleLabel(myRole)}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrowseTab(WidgetRef ref, List<Guild> availableGuilds) {
    if (availableGuilds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              t.noPublicGuild,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(gameProvider.notifier).loadAvailableGuilds(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: availableGuilds.length,
        itemBuilder: (context, index) {
          final g = availableGuilds[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        child: Text(
                          g.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(
                              '${g.memberCount}/${g.maxMembers} ${t.membersWord} • ${t.minLevel}: ${g.minLevel}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (g.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(g.description, style: const TextStyle(color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _joinTypeBadge(g.joinType),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => ref.read(gameProvider.notifier).joinGuild(g.id),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(t.join),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateTab(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: CreateGuildInline(
        onCreated: () {
          _loadGuilds();
          _tabController.animateTo(0);
        },
      ),
    );
  }

  Widget _buildGuildDetail(BuildContext context, WidgetRef ref, Guild guild, GameState state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(guild.name[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guild.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      '${guild.memberCount}/${guild.maxMembers} ${t.membersWord} • ${_roleLabel(guild.myRole ?? 'member')}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  final notifier = ref.read(gameProvider.notifier);
                  if (value == 'leave') {
                    final keepLog = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        bool showLog = true;
                        return StatefulBuilder(
                          builder: (context, setSt) => AlertDialog(
                            title: Text(t.leaveGuild),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.leaveGuildConfirm),
                                const SizedBox(height: 12),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: showLog,
                                  onChanged: (v) => setSt(() => showLog = v ?? true),
                                  title: const Text('Afficher mon départ dans le journal', style: TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, null), child: Text(t.cancel)),
                              ElevatedButton(onPressed: () => Navigator.pop(context, showLog), child: Text(t.leave)),
                            ],
                          ),
                        );
                      },
                    );
                    if (keepLog != null) {
                      await notifier.leaveGuild(showLog: keepLog);
                    }
                  } else if (value == 'members') {
                    await notifier.loadGuildMembers(guild.id);
                    setState(() => _guildDetailTab = 0);
                  } else if (value == 'quests') {
                    await notifier.loadGuildQuests(guild.id);
                    setState(() => _guildDetailTab = 1);
                  } else if (value == 'logs') {
                    await notifier.loadGuildLogs(guild.id);
                    setState(() => _guildDetailTab = 2);
                  } else if (value == 'chat') {
                    setState(() => _guildDetailTab = 3);
                  } else if (value == 'guild_leaderboard') {
                    if (context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildLeaderboardScreen()));
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'members', child: Text(t.members)),
                  PopupMenuItem(value: 'quests', child: Text(t.quests)),
                  PopupMenuItem(value: 'logs', child: Text(t.logs)),
                  PopupMenuItem(value: 'chat', child: Text(t.chat)),
                  PopupMenuItem(value: 'guild_leaderboard', child: Text(t.guildLeaderboard)),
                  PopupMenuItem(value: 'leave', child: Text(t.leaveGuild, style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildGuildContent(state, ref),
        ),
      ],
    );
  }

  Widget _buildGuildContent(GameState state, WidgetRef ref) {
    switch (_guildDetailTab) {
      case 0:
        return _buildMembersList(state.guildMembers);
      case 1:
        return _buildQuestsList(state.guildQuests);
      case 2:
        return _buildLogsList(state.guildLogs);
      case 3:
        return Column(
          children: [
            Expanded(
              child: state.guildMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(t.noMessages, style: TextStyle(color: Colors.grey[500])),
                          const SizedBox(height: 8),
                          Text(t.messagesHere, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    )
                  : _buildChatList(state.guildMessages),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: t.writeMessage,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (text) {
                        if (text.isNotEmpty) {
                          _chatController.clear();
                          ref.read(gameProvider.notifier).sendGuildMessage(text);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        final text = _chatController.text.trim();
                        if (text.isNotEmpty) {
                          _chatController.clear();
                          ref.read(gameProvider.notifier).sendGuildMessage(text);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return _buildMembersList(state.guildMembers);
    }
  }

  Widget _buildChatList(List<ChatMessage> messages) {
    // With reverse:true, the newest message is at the bottom (offset 0).
    // Scroll to bottom (newest) when messages change.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.jumpTo(_chatScrollController.position.minScrollExtent);
      }
    });
    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[messages.length - 1 - index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(msg.senderName, style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(msg.text),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersList(List<GuildMember> members) {
    return RefreshIndicator(
      onRefresh: () => ref.read(gameProvider.notifier).loadGuildMembers(ref.read(gameProvider).currentGuild?.id ?? ''),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final m = members[index];
          return ListTile(
            leading: CircleAvatar(child: Text(m.pseudo[0].toUpperCase())),
            title: Text(m.pseudo),
            subtitle: Text('${_roleLabel(m.role)} • Niv. ${m.level}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMemberProfile(context, m.pseudo),
          );
        },
      ),
    );
  }

  void _showMemberProfile(BuildContext context, String pseudo) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text('${t.profileOf} $pseudo'),
        content: SizedBox(
          width: 300,
          child: FutureBuilder<Map<String, dynamic>?>(
            future: ServerService.getUserProfileByPseudo(pseudo),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return Text(t.cannotLoadProfile);
              }
              final data = snapshot.data!;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _profileRow(t.level, '${data['level'] ?? 1}'),
                    _profileRow(t.globalXp, '${data['xp'] ?? 0}'),
                    _profileRow(t.coins, '${data['coins'] ?? 0}'),
                    _profileRow(t.streak, '${data['streak'] ?? 0} jours'),
                    _profileRow(t.questsCompletedLabel, '${data['total_quests_completed'] ?? 0}'),
                    _profileRow(t.referrals, '${data['referrals_count'] ?? 0}'),
                    _profileRow(t.badges, (data['badges'] as List?)?.join(', ') ?? t.none),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildQuestsList(List<GuildQuest> quests) {
    return RefreshIndicator(
      onRefresh: () => ref.read(gameProvider.notifier).loadGuildQuests(ref.read(gameProvider).currentGuild?.id ?? ''),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: quests.length,
        itemBuilder: (context, index) {
          final q = quests[index];
          final isActive = q.status == GuildQuestStatus.active;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(isActive ? Icons.check_circle_outline : Icons.check_circle, color: isActive ? null : Colors.green),
              title: Text(q.title),
              subtitle: Text('${q.xpReward} XP • ${q.coinReward}💰'),
              trailing: isActive ? IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => ref.read(gameProvider.notifier).completeGuildQuest(q.guildId, q.id),
              ) : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogsList(List<GuildLog> logs) {
    return RefreshIndicator(
      onRefresh: () => ref.read(gameProvider.notifier).loadGuildLogs(ref.read(gameProvider).currentGuild?.id ?? ''),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final l = logs[index];
          return ListTile(
            leading: Icon(_logIcon(l.actionType)),
            title: Text(l.actionType.name, style: const TextStyle(fontSize: 13)),
            subtitle: Text(l.actorPseudo, style: const TextStyle(fontSize: 11)),
            trailing: Text('${l.timestamp.hour}:${l.timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          );
        },
      ),
    );
  }

  String _roleLabel(dynamic role) {
    final r = role is GuildRole ? role.name : role.toString();
    switch (r) {
      case 'chief': return t.roleChief;
      case 'sub_chief': return t.roleSubChief;
      default: return t.roleMember;
    }
  }

  Widget _joinTypeBadge(dynamic joinType) {
    final j = joinType is GuildJoinType ? joinType : GuildJoinType.open;
    Color color;
    String label;
    switch (j) {
      case GuildJoinType.open:
        color = Colors.green;
        label = t.open;
        break;
      case GuildJoinType.criteria:
        color = Colors.orange;
        label = t.byCriteria;
        break;
      case GuildJoinType.private:
        color = Colors.red;
        label = t.private;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  IconData _logIcon(GuildLogActionType action) {
    switch (action) {
      case GuildLogActionType.join: return Icons.person_add;
      case GuildLogActionType.leave: return Icons.person_remove;
      case GuildLogActionType.kick: return Icons.block;
      case GuildLogActionType.promote: return Icons.arrow_upward;
      case GuildLogActionType.demote: return Icons.arrow_downward;
      case GuildLogActionType.transfer: return Icons.swap_horiz;
      case GuildLogActionType.quest_completed: return Icons.check_circle;
      case GuildLogActionType.update: return Icons.edit;
      case GuildLogActionType.invite_accepted: return Icons.person_add;
      case GuildLogActionType.quest_created: return Icons.add_task;
    }
  }
}

class CreateGuildInline extends ConsumerStatefulWidget {
  final VoidCallback? onCreated;
  const CreateGuildInline({super.key, this.onCreated});

  @override
  ConsumerState<CreateGuildInline> createState() => _CreateGuildInlineState();
}

class _CreateGuildInlineState extends ConsumerState<CreateGuildInline> {
  Translations get t => ref.read(translationsProvider);
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _minLevelController = TextEditingController(text: '0');
  final _maxMembersController = TextEditingController(text: '50');
  GuildJoinType _joinType = GuildJoinType.open;
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _minLevelController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.createGuildTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: t.guildName, border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descController,
          decoration: InputDecoration(labelText: t.description, border: OutlineInputBorder()),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<GuildJoinType>(
          value: _joinType,
          decoration: InputDecoration(labelText: t.membershipType, border: OutlineInputBorder()),
          items: GuildJoinType.values.map((jt) => DropdownMenuItem(
                value: jt,
                child: Text(
                  jt == GuildJoinType.open
                      ? t.open
                      : jt == GuildJoinType.criteria
                          ? t.byCriteria
                          : t.private,
                ),
              )).toList(),
          onChanged: (v) { if (v != null) setState(() => _joinType = v); },
        ),
        const SizedBox(height: 12),
        if (_joinType == GuildJoinType.criteria)
          TextField(
            controller: _minLevelController,
            decoration: InputDecoration(labelText: t.minLevel, border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _maxMembersController,
          decoration: InputDecoration(labelText: t.maxMembers, border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _creating ? null : _createGuild,
          child: _creating
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(t.createGuild),
        ),
      ],
    );
  }

  Future<void> _createGuild() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);
    await ref.read(gameProvider.notifier).createGuild(
      name,
      _descController.text.trim(),
      '',
      joinType: _joinType,
      minLevel: int.tryParse(_minLevelController.text) ?? 0,
      maxMembers: (int.tryParse(_maxMembersController.text) ?? 50).clamp(2, 50),
    );
    if (!mounted) return;
    setState(() => _creating = false);
    widget.onCreated?.call();
  }
}
