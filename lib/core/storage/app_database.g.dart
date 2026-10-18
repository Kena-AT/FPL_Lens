// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SquadPlayersTableTable extends SquadPlayersTable
    with TableInfo<$SquadPlayersTableTable, SquadPlayersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SquadPlayersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fplIdMeta = const VerificationMeta('fplId');
  @override
  late final GeneratedColumn<int> fplId = GeneratedColumn<int>(
    'fpl_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _webNameMeta = const VerificationMeta(
    'webName',
  );
  @override
  late final GeneratedColumn<String> webName = GeneratedColumn<String>(
    'web_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<int> teamId = GeneratedColumn<int>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamShortNameMeta = const VerificationMeta(
    'teamShortName',
  );
  @override
  late final GeneratedColumn<String> teamShortName = GeneratedColumn<String>(
    'team_short_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchasePriceTenthsMeta =
      const VerificationMeta('purchasePriceTenths');
  @override
  late final GeneratedColumn<int> purchasePriceTenths = GeneratedColumn<int>(
    'purchase_price_tenths',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sellingPriceTenthsMeta =
      const VerificationMeta('sellingPriceTenths');
  @override
  late final GeneratedColumn<int> sellingPriceTenths = GeneratedColumn<int>(
    'selling_price_tenths',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nowCostTenthsMeta = const VerificationMeta(
    'nowCostTenths',
  );
  @override
  late final GeneratedColumn<int> nowCostTenths = GeneratedColumn<int>(
    'now_cost_tenths',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newsMeta = const VerificationMeta('news');
  @override
  late final GeneratedColumn<String> news = GeneratedColumn<String>(
    'news',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chanceOfPlayingNextRoundMeta =
      const VerificationMeta('chanceOfPlayingNextRound');
  @override
  late final GeneratedColumn<int> chanceOfPlayingNextRound =
      GeneratedColumn<int>(
        'chance_of_playing_next_round',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isCaptainMeta = const VerificationMeta(
    'isCaptain',
  );
  @override
  late final GeneratedColumn<bool> isCaptain = GeneratedColumn<bool>(
    'is_captain',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_captain" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isViceCaptainMeta = const VerificationMeta(
    'isViceCaptain',
  );
  @override
  late final GeneratedColumn<bool> isViceCaptain = GeneratedColumn<bool>(
    'is_vice_captain',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_vice_captain" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _multiplierMeta = const VerificationMeta(
    'multiplier',
  );
  @override
  late final GeneratedColumn<int> multiplier = GeneratedColumn<int>(
    'multiplier',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _positionOrderMeta = const VerificationMeta(
    'positionOrder',
  );
  @override
  late final GeneratedColumn<int> positionOrder = GeneratedColumn<int>(
    'position_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceSourceMeta = const VerificationMeta(
    'priceSource',
  );
  @override
  late final GeneratedColumn<String> priceSource = GeneratedColumn<String>(
    'price_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fplId,
    webName,
    position,
    teamId,
    teamShortName,
    purchasePriceTenths,
    sellingPriceTenths,
    nowCostTenths,
    status,
    news,
    chanceOfPlayingNextRound,
    isCaptain,
    isViceCaptain,
    multiplier,
    positionOrder,
    priceSource,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'squad_players_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SquadPlayersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fpl_id')) {
      context.handle(
        _fplIdMeta,
        fplId.isAcceptableOrUnknown(data['fpl_id']!, _fplIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fplIdMeta);
    }
    if (data.containsKey('web_name')) {
      context.handle(
        _webNameMeta,
        webName.isAcceptableOrUnknown(data['web_name']!, _webNameMeta),
      );
    } else if (isInserting) {
      context.missing(_webNameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('team_short_name')) {
      context.handle(
        _teamShortNameMeta,
        teamShortName.isAcceptableOrUnknown(
          data['team_short_name']!,
          _teamShortNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_teamShortNameMeta);
    }
    if (data.containsKey('purchase_price_tenths')) {
      context.handle(
        _purchasePriceTenthsMeta,
        purchasePriceTenths.isAcceptableOrUnknown(
          data['purchase_price_tenths']!,
          _purchasePriceTenthsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchasePriceTenthsMeta);
    }
    if (data.containsKey('selling_price_tenths')) {
      context.handle(
        _sellingPriceTenthsMeta,
        sellingPriceTenths.isAcceptableOrUnknown(
          data['selling_price_tenths']!,
          _sellingPriceTenthsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sellingPriceTenthsMeta);
    }
    if (data.containsKey('now_cost_tenths')) {
      context.handle(
        _nowCostTenthsMeta,
        nowCostTenths.isAcceptableOrUnknown(
          data['now_cost_tenths']!,
          _nowCostTenthsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nowCostTenthsMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('news')) {
      context.handle(
        _newsMeta,
        news.isAcceptableOrUnknown(data['news']!, _newsMeta),
      );
    }
    if (data.containsKey('chance_of_playing_next_round')) {
      context.handle(
        _chanceOfPlayingNextRoundMeta,
        chanceOfPlayingNextRound.isAcceptableOrUnknown(
          data['chance_of_playing_next_round']!,
          _chanceOfPlayingNextRoundMeta,
        ),
      );
    }
    if (data.containsKey('is_captain')) {
      context.handle(
        _isCaptainMeta,
        isCaptain.isAcceptableOrUnknown(data['is_captain']!, _isCaptainMeta),
      );
    }
    if (data.containsKey('is_vice_captain')) {
      context.handle(
        _isViceCaptainMeta,
        isViceCaptain.isAcceptableOrUnknown(
          data['is_vice_captain']!,
          _isViceCaptainMeta,
        ),
      );
    }
    if (data.containsKey('multiplier')) {
      context.handle(
        _multiplierMeta,
        multiplier.isAcceptableOrUnknown(data['multiplier']!, _multiplierMeta),
      );
    }
    if (data.containsKey('position_order')) {
      context.handle(
        _positionOrderMeta,
        positionOrder.isAcceptableOrUnknown(
          data['position_order']!,
          _positionOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_positionOrderMeta);
    }
    if (data.containsKey('price_source')) {
      context.handle(
        _priceSourceMeta,
        priceSource.isAcceptableOrUnknown(
          data['price_source']!,
          _priceSourceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_priceSourceMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SquadPlayersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SquadPlayersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fplId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fpl_id'],
      )!,
      webName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}web_name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_id'],
      )!,
      teamShortName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_short_name'],
      )!,
      purchasePriceTenths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purchase_price_tenths'],
      )!,
      sellingPriceTenths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}selling_price_tenths'],
      )!,
      nowCostTenths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}now_cost_tenths'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      news: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}news'],
      ),
      chanceOfPlayingNextRound: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chance_of_playing_next_round'],
      ),
      isCaptain: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_captain'],
      )!,
      isViceCaptain: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_vice_captain'],
      )!,
      multiplier: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}multiplier'],
      )!,
      positionOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_order'],
      )!,
      priceSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price_source'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SquadPlayersTableTable createAlias(String alias) {
    return $SquadPlayersTableTable(attachedDatabase, alias);
  }
}

class SquadPlayersTableData extends DataClass
    implements Insertable<SquadPlayersTableData> {
  final int id;
  final int fplId;
  final String webName;
  final String position;
  final int teamId;
  final String teamShortName;
  final int purchasePriceTenths;
  final int sellingPriceTenths;
  final int nowCostTenths;
  final String status;
  final String? news;
  final int? chanceOfPlayingNextRound;
  final bool isCaptain;
  final bool isViceCaptain;
  final int multiplier;
  final int positionOrder;
  final String priceSource;
  final DateTime updatedAt;
  const SquadPlayersTableData({
    required this.id,
    required this.fplId,
    required this.webName,
    required this.position,
    required this.teamId,
    required this.teamShortName,
    required this.purchasePriceTenths,
    required this.sellingPriceTenths,
    required this.nowCostTenths,
    required this.status,
    this.news,
    this.chanceOfPlayingNextRound,
    required this.isCaptain,
    required this.isViceCaptain,
    required this.multiplier,
    required this.positionOrder,
    required this.priceSource,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['fpl_id'] = Variable<int>(fplId);
    map['web_name'] = Variable<String>(webName);
    map['position'] = Variable<String>(position);
    map['team_id'] = Variable<int>(teamId);
    map['team_short_name'] = Variable<String>(teamShortName);
    map['purchase_price_tenths'] = Variable<int>(purchasePriceTenths);
    map['selling_price_tenths'] = Variable<int>(sellingPriceTenths);
    map['now_cost_tenths'] = Variable<int>(nowCostTenths);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || news != null) {
      map['news'] = Variable<String>(news);
    }
    if (!nullToAbsent || chanceOfPlayingNextRound != null) {
      map['chance_of_playing_next_round'] = Variable<int>(
        chanceOfPlayingNextRound,
      );
    }
    map['is_captain'] = Variable<bool>(isCaptain);
    map['is_vice_captain'] = Variable<bool>(isViceCaptain);
    map['multiplier'] = Variable<int>(multiplier);
    map['position_order'] = Variable<int>(positionOrder);
    map['price_source'] = Variable<String>(priceSource);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SquadPlayersTableCompanion toCompanion(bool nullToAbsent) {
    return SquadPlayersTableCompanion(
      id: Value(id),
      fplId: Value(fplId),
      webName: Value(webName),
      position: Value(position),
      teamId: Value(teamId),
      teamShortName: Value(teamShortName),
      purchasePriceTenths: Value(purchasePriceTenths),
      sellingPriceTenths: Value(sellingPriceTenths),
      nowCostTenths: Value(nowCostTenths),
      status: Value(status),
      news: news == null && nullToAbsent ? const Value.absent() : Value(news),
      chanceOfPlayingNextRound: chanceOfPlayingNextRound == null && nullToAbsent
          ? const Value.absent()
          : Value(chanceOfPlayingNextRound),
      isCaptain: Value(isCaptain),
      isViceCaptain: Value(isViceCaptain),
      multiplier: Value(multiplier),
      positionOrder: Value(positionOrder),
      priceSource: Value(priceSource),
      updatedAt: Value(updatedAt),
    );
  }

  factory SquadPlayersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SquadPlayersTableData(
      id: serializer.fromJson<int>(json['id']),
      fplId: serializer.fromJson<int>(json['fplId']),
      webName: serializer.fromJson<String>(json['webName']),
      position: serializer.fromJson<String>(json['position']),
      teamId: serializer.fromJson<int>(json['teamId']),
      teamShortName: serializer.fromJson<String>(json['teamShortName']),
      purchasePriceTenths: serializer.fromJson<int>(
        json['purchasePriceTenths'],
      ),
      sellingPriceTenths: serializer.fromJson<int>(json['sellingPriceTenths']),
      nowCostTenths: serializer.fromJson<int>(json['nowCostTenths']),
      status: serializer.fromJson<String>(json['status']),
      news: serializer.fromJson<String?>(json['news']),
      chanceOfPlayingNextRound: serializer.fromJson<int?>(
        json['chanceOfPlayingNextRound'],
      ),
      isCaptain: serializer.fromJson<bool>(json['isCaptain']),
      isViceCaptain: serializer.fromJson<bool>(json['isViceCaptain']),
      multiplier: serializer.fromJson<int>(json['multiplier']),
      positionOrder: serializer.fromJson<int>(json['positionOrder']),
      priceSource: serializer.fromJson<String>(json['priceSource']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fplId': serializer.toJson<int>(fplId),
      'webName': serializer.toJson<String>(webName),
      'position': serializer.toJson<String>(position),
      'teamId': serializer.toJson<int>(teamId),
      'teamShortName': serializer.toJson<String>(teamShortName),
      'purchasePriceTenths': serializer.toJson<int>(purchasePriceTenths),
      'sellingPriceTenths': serializer.toJson<int>(sellingPriceTenths),
      'nowCostTenths': serializer.toJson<int>(nowCostTenths),
      'status': serializer.toJson<String>(status),
      'news': serializer.toJson<String?>(news),
      'chanceOfPlayingNextRound': serializer.toJson<int?>(
        chanceOfPlayingNextRound,
      ),
      'isCaptain': serializer.toJson<bool>(isCaptain),
      'isViceCaptain': serializer.toJson<bool>(isViceCaptain),
      'multiplier': serializer.toJson<int>(multiplier),
      'positionOrder': serializer.toJson<int>(positionOrder),
      'priceSource': serializer.toJson<String>(priceSource),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SquadPlayersTableData copyWith({
    int? id,
    int? fplId,
    String? webName,
    String? position,
    int? teamId,
    String? teamShortName,
    int? purchasePriceTenths,
    int? sellingPriceTenths,
    int? nowCostTenths,
    String? status,
    Value<String?> news = const Value.absent(),
    Value<int?> chanceOfPlayingNextRound = const Value.absent(),
    bool? isCaptain,
    bool? isViceCaptain,
    int? multiplier,
    int? positionOrder,
    String? priceSource,
    DateTime? updatedAt,
  }) => SquadPlayersTableData(
    id: id ?? this.id,
    fplId: fplId ?? this.fplId,
    webName: webName ?? this.webName,
    position: position ?? this.position,
    teamId: teamId ?? this.teamId,
    teamShortName: teamShortName ?? this.teamShortName,
    purchasePriceTenths: purchasePriceTenths ?? this.purchasePriceTenths,
    sellingPriceTenths: sellingPriceTenths ?? this.sellingPriceTenths,
    nowCostTenths: nowCostTenths ?? this.nowCostTenths,
    status: status ?? this.status,
    news: news.present ? news.value : this.news,
    chanceOfPlayingNextRound: chanceOfPlayingNextRound.present
        ? chanceOfPlayingNextRound.value
        : this.chanceOfPlayingNextRound,
    isCaptain: isCaptain ?? this.isCaptain,
    isViceCaptain: isViceCaptain ?? this.isViceCaptain,
    multiplier: multiplier ?? this.multiplier,
    positionOrder: positionOrder ?? this.positionOrder,
    priceSource: priceSource ?? this.priceSource,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SquadPlayersTableData copyWithCompanion(SquadPlayersTableCompanion data) {
    return SquadPlayersTableData(
      id: data.id.present ? data.id.value : this.id,
      fplId: data.fplId.present ? data.fplId.value : this.fplId,
      webName: data.webName.present ? data.webName.value : this.webName,
      position: data.position.present ? data.position.value : this.position,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      teamShortName: data.teamShortName.present
          ? data.teamShortName.value
          : this.teamShortName,
      purchasePriceTenths: data.purchasePriceTenths.present
          ? data.purchasePriceTenths.value
          : this.purchasePriceTenths,
      sellingPriceTenths: data.sellingPriceTenths.present
          ? data.sellingPriceTenths.value
          : this.sellingPriceTenths,
      nowCostTenths: data.nowCostTenths.present
          ? data.nowCostTenths.value
          : this.nowCostTenths,
      status: data.status.present ? data.status.value : this.status,
      news: data.news.present ? data.news.value : this.news,
      chanceOfPlayingNextRound: data.chanceOfPlayingNextRound.present
          ? data.chanceOfPlayingNextRound.value
          : this.chanceOfPlayingNextRound,
      isCaptain: data.isCaptain.present ? data.isCaptain.value : this.isCaptain,
      isViceCaptain: data.isViceCaptain.present
          ? data.isViceCaptain.value
          : this.isViceCaptain,
      multiplier: data.multiplier.present
          ? data.multiplier.value
          : this.multiplier,
      positionOrder: data.positionOrder.present
          ? data.positionOrder.value
          : this.positionOrder,
      priceSource: data.priceSource.present
          ? data.priceSource.value
          : this.priceSource,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SquadPlayersTableData(')
          ..write('id: $id, ')
          ..write('fplId: $fplId, ')
          ..write('webName: $webName, ')
          ..write('position: $position, ')
          ..write('teamId: $teamId, ')
          ..write('teamShortName: $teamShortName, ')
          ..write('purchasePriceTenths: $purchasePriceTenths, ')
          ..write('sellingPriceTenths: $sellingPriceTenths, ')
          ..write('nowCostTenths: $nowCostTenths, ')
          ..write('status: $status, ')
          ..write('news: $news, ')
          ..write('chanceOfPlayingNextRound: $chanceOfPlayingNextRound, ')
          ..write('isCaptain: $isCaptain, ')
          ..write('isViceCaptain: $isViceCaptain, ')
          ..write('multiplier: $multiplier, ')
          ..write('positionOrder: $positionOrder, ')
          ..write('priceSource: $priceSource, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fplId,
    webName,
    position,
    teamId,
    teamShortName,
    purchasePriceTenths,
    sellingPriceTenths,
    nowCostTenths,
    status,
    news,
    chanceOfPlayingNextRound,
    isCaptain,
    isViceCaptain,
    multiplier,
    positionOrder,
    priceSource,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SquadPlayersTableData &&
          other.id == this.id &&
          other.fplId == this.fplId &&
          other.webName == this.webName &&
          other.position == this.position &&
          other.teamId == this.teamId &&
          other.teamShortName == this.teamShortName &&
          other.purchasePriceTenths == this.purchasePriceTenths &&
          other.sellingPriceTenths == this.sellingPriceTenths &&
          other.nowCostTenths == this.nowCostTenths &&
          other.status == this.status &&
          other.news == this.news &&
          other.chanceOfPlayingNextRound == this.chanceOfPlayingNextRound &&
          other.isCaptain == this.isCaptain &&
          other.isViceCaptain == this.isViceCaptain &&
          other.multiplier == this.multiplier &&
          other.positionOrder == this.positionOrder &&
          other.priceSource == this.priceSource &&
          other.updatedAt == this.updatedAt);
}

class SquadPlayersTableCompanion
    extends UpdateCompanion<SquadPlayersTableData> {
  final Value<int> id;
  final Value<int> fplId;
  final Value<String> webName;
  final Value<String> position;
  final Value<int> teamId;
  final Value<String> teamShortName;
  final Value<int> purchasePriceTenths;
  final Value<int> sellingPriceTenths;
  final Value<int> nowCostTenths;
  final Value<String> status;
  final Value<String?> news;
  final Value<int?> chanceOfPlayingNextRound;
  final Value<bool> isCaptain;
  final Value<bool> isViceCaptain;
  final Value<int> multiplier;
  final Value<int> positionOrder;
  final Value<String> priceSource;
  final Value<DateTime> updatedAt;
  const SquadPlayersTableCompanion({
    this.id = const Value.absent(),
    this.fplId = const Value.absent(),
    this.webName = const Value.absent(),
    this.position = const Value.absent(),
    this.teamId = const Value.absent(),
    this.teamShortName = const Value.absent(),
    this.purchasePriceTenths = const Value.absent(),
    this.sellingPriceTenths = const Value.absent(),
    this.nowCostTenths = const Value.absent(),
    this.status = const Value.absent(),
    this.news = const Value.absent(),
    this.chanceOfPlayingNextRound = const Value.absent(),
    this.isCaptain = const Value.absent(),
    this.isViceCaptain = const Value.absent(),
    this.multiplier = const Value.absent(),
    this.positionOrder = const Value.absent(),
    this.priceSource = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SquadPlayersTableCompanion.insert({
    this.id = const Value.absent(),
    required int fplId,
    required String webName,
    required String position,
    required int teamId,
    required String teamShortName,
    required int purchasePriceTenths,
    required int sellingPriceTenths,
    required int nowCostTenths,
    required String status,
    this.news = const Value.absent(),
    this.chanceOfPlayingNextRound = const Value.absent(),
    this.isCaptain = const Value.absent(),
    this.isViceCaptain = const Value.absent(),
    this.multiplier = const Value.absent(),
    required int positionOrder,
    required String priceSource,
    required DateTime updatedAt,
  }) : fplId = Value(fplId),
       webName = Value(webName),
       position = Value(position),
       teamId = Value(teamId),
       teamShortName = Value(teamShortName),
       purchasePriceTenths = Value(purchasePriceTenths),
       sellingPriceTenths = Value(sellingPriceTenths),
       nowCostTenths = Value(nowCostTenths),
       status = Value(status),
       positionOrder = Value(positionOrder),
       priceSource = Value(priceSource),
       updatedAt = Value(updatedAt);
  static Insertable<SquadPlayersTableData> custom({
    Expression<int>? id,
    Expression<int>? fplId,
    Expression<String>? webName,
    Expression<String>? position,
    Expression<int>? teamId,
    Expression<String>? teamShortName,
    Expression<int>? purchasePriceTenths,
    Expression<int>? sellingPriceTenths,
    Expression<int>? nowCostTenths,
    Expression<String>? status,
    Expression<String>? news,
    Expression<int>? chanceOfPlayingNextRound,
    Expression<bool>? isCaptain,
    Expression<bool>? isViceCaptain,
    Expression<int>? multiplier,
    Expression<int>? positionOrder,
    Expression<String>? priceSource,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fplId != null) 'fpl_id': fplId,
      if (webName != null) 'web_name': webName,
      if (position != null) 'position': position,
      if (teamId != null) 'team_id': teamId,
      if (teamShortName != null) 'team_short_name': teamShortName,
      if (purchasePriceTenths != null)
        'purchase_price_tenths': purchasePriceTenths,
      if (sellingPriceTenths != null)
        'selling_price_tenths': sellingPriceTenths,
      if (nowCostTenths != null) 'now_cost_tenths': nowCostTenths,
      if (status != null) 'status': status,
      if (news != null) 'news': news,
      if (chanceOfPlayingNextRound != null)
        'chance_of_playing_next_round': chanceOfPlayingNextRound,
      if (isCaptain != null) 'is_captain': isCaptain,
      if (isViceCaptain != null) 'is_vice_captain': isViceCaptain,
      if (multiplier != null) 'multiplier': multiplier,
      if (positionOrder != null) 'position_order': positionOrder,
      if (priceSource != null) 'price_source': priceSource,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SquadPlayersTableCompanion copyWith({
    Value<int>? id,
    Value<int>? fplId,
    Value<String>? webName,
    Value<String>? position,
    Value<int>? teamId,
    Value<String>? teamShortName,
    Value<int>? purchasePriceTenths,
    Value<int>? sellingPriceTenths,
    Value<int>? nowCostTenths,
    Value<String>? status,
    Value<String?>? news,
    Value<int?>? chanceOfPlayingNextRound,
    Value<bool>? isCaptain,
    Value<bool>? isViceCaptain,
    Value<int>? multiplier,
    Value<int>? positionOrder,
    Value<String>? priceSource,
    Value<DateTime>? updatedAt,
  }) {
    return SquadPlayersTableCompanion(
      id: id ?? this.id,
      fplId: fplId ?? this.fplId,
      webName: webName ?? this.webName,
      position: position ?? this.position,
      teamId: teamId ?? this.teamId,
      teamShortName: teamShortName ?? this.teamShortName,
      purchasePriceTenths: purchasePriceTenths ?? this.purchasePriceTenths,
      sellingPriceTenths: sellingPriceTenths ?? this.sellingPriceTenths,
      nowCostTenths: nowCostTenths ?? this.nowCostTenths,
      status: status ?? this.status,
      news: news ?? this.news,
      chanceOfPlayingNextRound:
          chanceOfPlayingNextRound ?? this.chanceOfPlayingNextRound,
      isCaptain: isCaptain ?? this.isCaptain,
      isViceCaptain: isViceCaptain ?? this.isViceCaptain,
      multiplier: multiplier ?? this.multiplier,
      positionOrder: positionOrder ?? this.positionOrder,
      priceSource: priceSource ?? this.priceSource,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fplId.present) {
      map['fpl_id'] = Variable<int>(fplId.value);
    }
    if (webName.present) {
      map['web_name'] = Variable<String>(webName.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<int>(teamId.value);
    }
    if (teamShortName.present) {
      map['team_short_name'] = Variable<String>(teamShortName.value);
    }
    if (purchasePriceTenths.present) {
      map['purchase_price_tenths'] = Variable<int>(purchasePriceTenths.value);
    }
    if (sellingPriceTenths.present) {
      map['selling_price_tenths'] = Variable<int>(sellingPriceTenths.value);
    }
    if (nowCostTenths.present) {
      map['now_cost_tenths'] = Variable<int>(nowCostTenths.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (news.present) {
      map['news'] = Variable<String>(news.value);
    }
    if (chanceOfPlayingNextRound.present) {
      map['chance_of_playing_next_round'] = Variable<int>(
        chanceOfPlayingNextRound.value,
      );
    }
    if (isCaptain.present) {
      map['is_captain'] = Variable<bool>(isCaptain.value);
    }
    if (isViceCaptain.present) {
      map['is_vice_captain'] = Variable<bool>(isViceCaptain.value);
    }
    if (multiplier.present) {
      map['multiplier'] = Variable<int>(multiplier.value);
    }
    if (positionOrder.present) {
      map['position_order'] = Variable<int>(positionOrder.value);
    }
    if (priceSource.present) {
      map['price_source'] = Variable<String>(priceSource.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SquadPlayersTableCompanion(')
          ..write('id: $id, ')
          ..write('fplId: $fplId, ')
          ..write('webName: $webName, ')
          ..write('position: $position, ')
          ..write('teamId: $teamId, ')
          ..write('teamShortName: $teamShortName, ')
          ..write('purchasePriceTenths: $purchasePriceTenths, ')
          ..write('sellingPriceTenths: $sellingPriceTenths, ')
          ..write('nowCostTenths: $nowCostTenths, ')
          ..write('status: $status, ')
          ..write('news: $news, ')
          ..write('chanceOfPlayingNextRound: $chanceOfPlayingNextRound, ')
          ..write('isCaptain: $isCaptain, ')
          ..write('isViceCaptain: $isViceCaptain, ')
          ..write('multiplier: $multiplier, ')
          ..write('positionOrder: $positionOrder, ')
          ..write('priceSource: $priceSource, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PurchasePricesTableTable extends PurchasePricesTable
    with TableInfo<$PurchasePricesTableTable, PurchasePricesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchasePricesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerFplIdMeta = const VerificationMeta(
    'playerFplId',
  );
  @override
  late final GeneratedColumn<int> playerFplId = GeneratedColumn<int>(
    'player_fpl_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasePriceTenthsMeta =
      const VerificationMeta('purchasePriceTenths');
  @override
  late final GeneratedColumn<int> purchasePriceTenths = GeneratedColumn<int>(
    'purchase_price_tenths',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isConfirmedMeta = const VerificationMeta(
    'isConfirmed',
  );
  @override
  late final GeneratedColumn<bool> isConfirmed = GeneratedColumn<bool>(
    'is_confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    playerFplId,
    purchasePriceTenths,
    source,
    isConfirmed,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_prices_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchasePricesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_fpl_id')) {
      context.handle(
        _playerFplIdMeta,
        playerFplId.isAcceptableOrUnknown(
          data['player_fpl_id']!,
          _playerFplIdMeta,
        ),
      );
    }
    if (data.containsKey('purchase_price_tenths')) {
      context.handle(
        _purchasePriceTenthsMeta,
        purchasePriceTenths.isAcceptableOrUnknown(
          data['purchase_price_tenths']!,
          _purchasePriceTenthsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchasePriceTenthsMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('is_confirmed')) {
      context.handle(
        _isConfirmedMeta,
        isConfirmed.isAcceptableOrUnknown(
          data['is_confirmed']!,
          _isConfirmedMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerFplId};
  @override
  PurchasePricesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchasePricesTableData(
      playerFplId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_fpl_id'],
      )!,
      purchasePriceTenths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purchase_price_tenths'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      isConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_confirmed'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PurchasePricesTableTable createAlias(String alias) {
    return $PurchasePricesTableTable(attachedDatabase, alias);
  }
}

class PurchasePricesTableData extends DataClass
    implements Insertable<PurchasePricesTableData> {
  final int playerFplId;
  final int purchasePriceTenths;
  final String source;
  final bool isConfirmed;
  final DateTime updatedAt;
  const PurchasePricesTableData({
    required this.playerFplId,
    required this.purchasePriceTenths,
    required this.source,
    required this.isConfirmed,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_fpl_id'] = Variable<int>(playerFplId);
    map['purchase_price_tenths'] = Variable<int>(purchasePriceTenths);
    map['source'] = Variable<String>(source);
    map['is_confirmed'] = Variable<bool>(isConfirmed);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PurchasePricesTableCompanion toCompanion(bool nullToAbsent) {
    return PurchasePricesTableCompanion(
      playerFplId: Value(playerFplId),
      purchasePriceTenths: Value(purchasePriceTenths),
      source: Value(source),
      isConfirmed: Value(isConfirmed),
      updatedAt: Value(updatedAt),
    );
  }

  factory PurchasePricesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchasePricesTableData(
      playerFplId: serializer.fromJson<int>(json['playerFplId']),
      purchasePriceTenths: serializer.fromJson<int>(
        json['purchasePriceTenths'],
      ),
      source: serializer.fromJson<String>(json['source']),
      isConfirmed: serializer.fromJson<bool>(json['isConfirmed']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerFplId': serializer.toJson<int>(playerFplId),
      'purchasePriceTenths': serializer.toJson<int>(purchasePriceTenths),
      'source': serializer.toJson<String>(source),
      'isConfirmed': serializer.toJson<bool>(isConfirmed),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PurchasePricesTableData copyWith({
    int? playerFplId,
    int? purchasePriceTenths,
    String? source,
    bool? isConfirmed,
    DateTime? updatedAt,
  }) => PurchasePricesTableData(
    playerFplId: playerFplId ?? this.playerFplId,
    purchasePriceTenths: purchasePriceTenths ?? this.purchasePriceTenths,
    source: source ?? this.source,
    isConfirmed: isConfirmed ?? this.isConfirmed,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PurchasePricesTableData copyWithCompanion(PurchasePricesTableCompanion data) {
    return PurchasePricesTableData(
      playerFplId: data.playerFplId.present
          ? data.playerFplId.value
          : this.playerFplId,
      purchasePriceTenths: data.purchasePriceTenths.present
          ? data.purchasePriceTenths.value
          : this.purchasePriceTenths,
      source: data.source.present ? data.source.value : this.source,
      isConfirmed: data.isConfirmed.present
          ? data.isConfirmed.value
          : this.isConfirmed,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchasePricesTableData(')
          ..write('playerFplId: $playerFplId, ')
          ..write('purchasePriceTenths: $purchasePriceTenths, ')
          ..write('source: $source, ')
          ..write('isConfirmed: $isConfirmed, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    playerFplId,
    purchasePriceTenths,
    source,
    isConfirmed,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchasePricesTableData &&
          other.playerFplId == this.playerFplId &&
          other.purchasePriceTenths == this.purchasePriceTenths &&
          other.source == this.source &&
          other.isConfirmed == this.isConfirmed &&
          other.updatedAt == this.updatedAt);
}

class PurchasePricesTableCompanion
    extends UpdateCompanion<PurchasePricesTableData> {
  final Value<int> playerFplId;
  final Value<int> purchasePriceTenths;
  final Value<String> source;
  final Value<bool> isConfirmed;
  final Value<DateTime> updatedAt;
  const PurchasePricesTableCompanion({
    this.playerFplId = const Value.absent(),
    this.purchasePriceTenths = const Value.absent(),
    this.source = const Value.absent(),
    this.isConfirmed = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PurchasePricesTableCompanion.insert({
    this.playerFplId = const Value.absent(),
    required int purchasePriceTenths,
    required String source,
    this.isConfirmed = const Value.absent(),
    required DateTime updatedAt,
  }) : purchasePriceTenths = Value(purchasePriceTenths),
       source = Value(source),
       updatedAt = Value(updatedAt);
  static Insertable<PurchasePricesTableData> custom({
    Expression<int>? playerFplId,
    Expression<int>? purchasePriceTenths,
    Expression<String>? source,
    Expression<bool>? isConfirmed,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (playerFplId != null) 'player_fpl_id': playerFplId,
      if (purchasePriceTenths != null)
        'purchase_price_tenths': purchasePriceTenths,
      if (source != null) 'source': source,
      if (isConfirmed != null) 'is_confirmed': isConfirmed,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PurchasePricesTableCompanion copyWith({
    Value<int>? playerFplId,
    Value<int>? purchasePriceTenths,
    Value<String>? source,
    Value<bool>? isConfirmed,
    Value<DateTime>? updatedAt,
  }) {
    return PurchasePricesTableCompanion(
      playerFplId: playerFplId ?? this.playerFplId,
      purchasePriceTenths: purchasePriceTenths ?? this.purchasePriceTenths,
      source: source ?? this.source,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerFplId.present) {
      map['player_fpl_id'] = Variable<int>(playerFplId.value);
    }
    if (purchasePriceTenths.present) {
      map['purchase_price_tenths'] = Variable<int>(purchasePriceTenths.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (isConfirmed.present) {
      map['is_confirmed'] = Variable<bool>(isConfirmed.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchasePricesTableCompanion(')
          ..write('playerFplId: $playerFplId, ')
          ..write('purchasePriceTenths: $purchasePriceTenths, ')
          ..write('source: $source, ')
          ..write('isConfirmed: $isConfirmed, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LineupResultsTableTable extends LineupResultsTable
    with TableInfo<$LineupResultsTableTable, LineupResultsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LineupResultsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameweekMeta = const VerificationMeta(
    'gameweek',
  );
  @override
  late final GeneratedColumn<int> gameweek = GeneratedColumn<int>(
    'gameweek',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _starting11FplIdsMeta = const VerificationMeta(
    'starting11FplIds',
  );
  @override
  late final GeneratedColumn<String> starting11FplIds = GeneratedColumn<String>(
    'starting11_fpl_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _benchFplIdsMeta = const VerificationMeta(
    'benchFplIds',
  );
  @override
  late final GeneratedColumn<String> benchFplIds = GeneratedColumn<String>(
    'bench_fpl_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _captainFplIdMeta = const VerificationMeta(
    'captainFplId',
  );
  @override
  late final GeneratedColumn<int> captainFplId = GeneratedColumn<int>(
    'captain_fpl_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _viceCaptainFplIdMeta = const VerificationMeta(
    'viceCaptainFplId',
  );
  @override
  late final GeneratedColumn<int> viceCaptainFplId = GeneratedColumn<int>(
    'vice_captain_fpl_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectedTotalPointsMeta =
      const VerificationMeta('projectedTotalPoints');
  @override
  late final GeneratedColumn<double> projectedTotalPoints =
      GeneratedColumn<double>(
        'projected_total_points',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _modelVersionMeta = const VerificationMeta(
    'modelVersion',
  );
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
    'model_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectionRunIdMeta = const VerificationMeta(
    'projectionRunId',
  );
  @override
  late final GeneratedColumn<String> projectionRunId = GeneratedColumn<String>(
    'projection_run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _computedAtMeta = const VerificationMeta(
    'computedAt',
  );
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
    'computed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameweek,
    starting11FplIds,
    benchFplIds,
    captainFplId,
    viceCaptainFplId,
    projectedTotalPoints,
    modelVersion,
    projectionRunId,
    computedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lineup_results_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LineupResultsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('gameweek')) {
      context.handle(
        _gameweekMeta,
        gameweek.isAcceptableOrUnknown(data['gameweek']!, _gameweekMeta),
      );
    } else if (isInserting) {
      context.missing(_gameweekMeta);
    }
    if (data.containsKey('starting11_fpl_ids')) {
      context.handle(
        _starting11FplIdsMeta,
        starting11FplIds.isAcceptableOrUnknown(
          data['starting11_fpl_ids']!,
          _starting11FplIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_starting11FplIdsMeta);
    }
    if (data.containsKey('bench_fpl_ids')) {
      context.handle(
        _benchFplIdsMeta,
        benchFplIds.isAcceptableOrUnknown(
          data['bench_fpl_ids']!,
          _benchFplIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_benchFplIdsMeta);
    }
    if (data.containsKey('captain_fpl_id')) {
      context.handle(
        _captainFplIdMeta,
        captainFplId.isAcceptableOrUnknown(
          data['captain_fpl_id']!,
          _captainFplIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_captainFplIdMeta);
    }
    if (data.containsKey('vice_captain_fpl_id')) {
      context.handle(
        _viceCaptainFplIdMeta,
        viceCaptainFplId.isAcceptableOrUnknown(
          data['vice_captain_fpl_id']!,
          _viceCaptainFplIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_viceCaptainFplIdMeta);
    }
    if (data.containsKey('projected_total_points')) {
      context.handle(
        _projectedTotalPointsMeta,
        projectedTotalPoints.isAcceptableOrUnknown(
          data['projected_total_points']!,
          _projectedTotalPointsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectedTotalPointsMeta);
    }
    if (data.containsKey('model_version')) {
      context.handle(
        _modelVersionMeta,
        modelVersion.isAcceptableOrUnknown(
          data['model_version']!,
          _modelVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelVersionMeta);
    }
    if (data.containsKey('projection_run_id')) {
      context.handle(
        _projectionRunIdMeta,
        projectionRunId.isAcceptableOrUnknown(
          data['projection_run_id']!,
          _projectionRunIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectionRunIdMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
        _computedAtMeta,
        computedAt.isAcceptableOrUnknown(data['computed_at']!, _computedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LineupResultsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LineupResultsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameweek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gameweek'],
      )!,
      starting11FplIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}starting11_fpl_ids'],
      )!,
      benchFplIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bench_fpl_ids'],
      )!,
      captainFplId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}captain_fpl_id'],
      )!,
      viceCaptainFplId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vice_captain_fpl_id'],
      )!,
      projectedTotalPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}projected_total_points'],
      )!,
      modelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_version'],
      )!,
      projectionRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}projection_run_id'],
      )!,
      computedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}computed_at'],
      )!,
    );
  }

  @override
  $LineupResultsTableTable createAlias(String alias) {
    return $LineupResultsTableTable(attachedDatabase, alias);
  }
}

class LineupResultsTableData extends DataClass
    implements Insertable<LineupResultsTableData> {
  final int id;
  final int gameweek;
  final String starting11FplIds;
  final String benchFplIds;
  final int captainFplId;
  final int viceCaptainFplId;
  final double projectedTotalPoints;
  final String modelVersion;
  final String projectionRunId;
  final DateTime computedAt;
  const LineupResultsTableData({
    required this.id,
    required this.gameweek,
    required this.starting11FplIds,
    required this.benchFplIds,
    required this.captainFplId,
    required this.viceCaptainFplId,
    required this.projectedTotalPoints,
    required this.modelVersion,
    required this.projectionRunId,
    required this.computedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['gameweek'] = Variable<int>(gameweek);
    map['starting11_fpl_ids'] = Variable<String>(starting11FplIds);
    map['bench_fpl_ids'] = Variable<String>(benchFplIds);
    map['captain_fpl_id'] = Variable<int>(captainFplId);
    map['vice_captain_fpl_id'] = Variable<int>(viceCaptainFplId);
    map['projected_total_points'] = Variable<double>(projectedTotalPoints);
    map['model_version'] = Variable<String>(modelVersion);
    map['projection_run_id'] = Variable<String>(projectionRunId);
    map['computed_at'] = Variable<DateTime>(computedAt);
    return map;
  }

  LineupResultsTableCompanion toCompanion(bool nullToAbsent) {
    return LineupResultsTableCompanion(
      id: Value(id),
      gameweek: Value(gameweek),
      starting11FplIds: Value(starting11FplIds),
      benchFplIds: Value(benchFplIds),
      captainFplId: Value(captainFplId),
      viceCaptainFplId: Value(viceCaptainFplId),
      projectedTotalPoints: Value(projectedTotalPoints),
      modelVersion: Value(modelVersion),
      projectionRunId: Value(projectionRunId),
      computedAt: Value(computedAt),
    );
  }

  factory LineupResultsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LineupResultsTableData(
      id: serializer.fromJson<int>(json['id']),
      gameweek: serializer.fromJson<int>(json['gameweek']),
      starting11FplIds: serializer.fromJson<String>(json['starting11FplIds']),
      benchFplIds: serializer.fromJson<String>(json['benchFplIds']),
      captainFplId: serializer.fromJson<int>(json['captainFplId']),
      viceCaptainFplId: serializer.fromJson<int>(json['viceCaptainFplId']),
      projectedTotalPoints: serializer.fromJson<double>(
        json['projectedTotalPoints'],
      ),
      modelVersion: serializer.fromJson<String>(json['modelVersion']),
      projectionRunId: serializer.fromJson<String>(json['projectionRunId']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameweek': serializer.toJson<int>(gameweek),
      'starting11FplIds': serializer.toJson<String>(starting11FplIds),
      'benchFplIds': serializer.toJson<String>(benchFplIds),
      'captainFplId': serializer.toJson<int>(captainFplId),
      'viceCaptainFplId': serializer.toJson<int>(viceCaptainFplId),
      'projectedTotalPoints': serializer.toJson<double>(projectedTotalPoints),
      'modelVersion': serializer.toJson<String>(modelVersion),
      'projectionRunId': serializer.toJson<String>(projectionRunId),
      'computedAt': serializer.toJson<DateTime>(computedAt),
    };
  }

  LineupResultsTableData copyWith({
    int? id,
    int? gameweek,
    String? starting11FplIds,
    String? benchFplIds,
    int? captainFplId,
    int? viceCaptainFplId,
    double? projectedTotalPoints,
    String? modelVersion,
    String? projectionRunId,
    DateTime? computedAt,
  }) => LineupResultsTableData(
    id: id ?? this.id,
    gameweek: gameweek ?? this.gameweek,
    starting11FplIds: starting11FplIds ?? this.starting11FplIds,
    benchFplIds: benchFplIds ?? this.benchFplIds,
    captainFplId: captainFplId ?? this.captainFplId,
    viceCaptainFplId: viceCaptainFplId ?? this.viceCaptainFplId,
    projectedTotalPoints: projectedTotalPoints ?? this.projectedTotalPoints,
    modelVersion: modelVersion ?? this.modelVersion,
    projectionRunId: projectionRunId ?? this.projectionRunId,
    computedAt: computedAt ?? this.computedAt,
  );
  LineupResultsTableData copyWithCompanion(LineupResultsTableCompanion data) {
    return LineupResultsTableData(
      id: data.id.present ? data.id.value : this.id,
      gameweek: data.gameweek.present ? data.gameweek.value : this.gameweek,
      starting11FplIds: data.starting11FplIds.present
          ? data.starting11FplIds.value
          : this.starting11FplIds,
      benchFplIds: data.benchFplIds.present
          ? data.benchFplIds.value
          : this.benchFplIds,
      captainFplId: data.captainFplId.present
          ? data.captainFplId.value
          : this.captainFplId,
      viceCaptainFplId: data.viceCaptainFplId.present
          ? data.viceCaptainFplId.value
          : this.viceCaptainFplId,
      projectedTotalPoints: data.projectedTotalPoints.present
          ? data.projectedTotalPoints.value
          : this.projectedTotalPoints,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      projectionRunId: data.projectionRunId.present
          ? data.projectionRunId.value
          : this.projectionRunId,
      computedAt: data.computedAt.present
          ? data.computedAt.value
          : this.computedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LineupResultsTableData(')
          ..write('id: $id, ')
          ..write('gameweek: $gameweek, ')
          ..write('starting11FplIds: $starting11FplIds, ')
          ..write('benchFplIds: $benchFplIds, ')
          ..write('captainFplId: $captainFplId, ')
          ..write('viceCaptainFplId: $viceCaptainFplId, ')
          ..write('projectedTotalPoints: $projectedTotalPoints, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('projectionRunId: $projectionRunId, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gameweek,
    starting11FplIds,
    benchFplIds,
    captainFplId,
    viceCaptainFplId,
    projectedTotalPoints,
    modelVersion,
    projectionRunId,
    computedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LineupResultsTableData &&
          other.id == this.id &&
          other.gameweek == this.gameweek &&
          other.starting11FplIds == this.starting11FplIds &&
          other.benchFplIds == this.benchFplIds &&
          other.captainFplId == this.captainFplId &&
          other.viceCaptainFplId == this.viceCaptainFplId &&
          other.projectedTotalPoints == this.projectedTotalPoints &&
          other.modelVersion == this.modelVersion &&
          other.projectionRunId == this.projectionRunId &&
          other.computedAt == this.computedAt);
}

class LineupResultsTableCompanion
    extends UpdateCompanion<LineupResultsTableData> {
  final Value<int> id;
  final Value<int> gameweek;
  final Value<String> starting11FplIds;
  final Value<String> benchFplIds;
  final Value<int> captainFplId;
  final Value<int> viceCaptainFplId;
  final Value<double> projectedTotalPoints;
  final Value<String> modelVersion;
  final Value<String> projectionRunId;
  final Value<DateTime> computedAt;
  const LineupResultsTableCompanion({
    this.id = const Value.absent(),
    this.gameweek = const Value.absent(),
    this.starting11FplIds = const Value.absent(),
    this.benchFplIds = const Value.absent(),
    this.captainFplId = const Value.absent(),
    this.viceCaptainFplId = const Value.absent(),
    this.projectedTotalPoints = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.projectionRunId = const Value.absent(),
    this.computedAt = const Value.absent(),
  });
  LineupResultsTableCompanion.insert({
    this.id = const Value.absent(),
    required int gameweek,
    required String starting11FplIds,
    required String benchFplIds,
    required int captainFplId,
    required int viceCaptainFplId,
    required double projectedTotalPoints,
    required String modelVersion,
    required String projectionRunId,
    required DateTime computedAt,
  }) : gameweek = Value(gameweek),
       starting11FplIds = Value(starting11FplIds),
       benchFplIds = Value(benchFplIds),
       captainFplId = Value(captainFplId),
       viceCaptainFplId = Value(viceCaptainFplId),
       projectedTotalPoints = Value(projectedTotalPoints),
       modelVersion = Value(modelVersion),
       projectionRunId = Value(projectionRunId),
       computedAt = Value(computedAt);
  static Insertable<LineupResultsTableData> custom({
    Expression<int>? id,
    Expression<int>? gameweek,
    Expression<String>? starting11FplIds,
    Expression<String>? benchFplIds,
    Expression<int>? captainFplId,
    Expression<int>? viceCaptainFplId,
    Expression<double>? projectedTotalPoints,
    Expression<String>? modelVersion,
    Expression<String>? projectionRunId,
    Expression<DateTime>? computedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameweek != null) 'gameweek': gameweek,
      if (starting11FplIds != null) 'starting11_fpl_ids': starting11FplIds,
      if (benchFplIds != null) 'bench_fpl_ids': benchFplIds,
      if (captainFplId != null) 'captain_fpl_id': captainFplId,
      if (viceCaptainFplId != null) 'vice_captain_fpl_id': viceCaptainFplId,
      if (projectedTotalPoints != null)
        'projected_total_points': projectedTotalPoints,
      if (modelVersion != null) 'model_version': modelVersion,
      if (projectionRunId != null) 'projection_run_id': projectionRunId,
      if (computedAt != null) 'computed_at': computedAt,
    });
  }

  LineupResultsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? gameweek,
    Value<String>? starting11FplIds,
    Value<String>? benchFplIds,
    Value<int>? captainFplId,
    Value<int>? viceCaptainFplId,
    Value<double>? projectedTotalPoints,
    Value<String>? modelVersion,
    Value<String>? projectionRunId,
    Value<DateTime>? computedAt,
  }) {
    return LineupResultsTableCompanion(
      id: id ?? this.id,
      gameweek: gameweek ?? this.gameweek,
      starting11FplIds: starting11FplIds ?? this.starting11FplIds,
      benchFplIds: benchFplIds ?? this.benchFplIds,
      captainFplId: captainFplId ?? this.captainFplId,
      viceCaptainFplId: viceCaptainFplId ?? this.viceCaptainFplId,
      projectedTotalPoints: projectedTotalPoints ?? this.projectedTotalPoints,
      modelVersion: modelVersion ?? this.modelVersion,
      projectionRunId: projectionRunId ?? this.projectionRunId,
      computedAt: computedAt ?? this.computedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameweek.present) {
      map['gameweek'] = Variable<int>(gameweek.value);
    }
    if (starting11FplIds.present) {
      map['starting11_fpl_ids'] = Variable<String>(starting11FplIds.value);
    }
    if (benchFplIds.present) {
      map['bench_fpl_ids'] = Variable<String>(benchFplIds.value);
    }
    if (captainFplId.present) {
      map['captain_fpl_id'] = Variable<int>(captainFplId.value);
    }
    if (viceCaptainFplId.present) {
      map['vice_captain_fpl_id'] = Variable<int>(viceCaptainFplId.value);
    }
    if (projectedTotalPoints.present) {
      map['projected_total_points'] = Variable<double>(
        projectedTotalPoints.value,
      );
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (projectionRunId.present) {
      map['projection_run_id'] = Variable<String>(projectionRunId.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LineupResultsTableCompanion(')
          ..write('id: $id, ')
          ..write('gameweek: $gameweek, ')
          ..write('starting11FplIds: $starting11FplIds, ')
          ..write('benchFplIds: $benchFplIds, ')
          ..write('captainFplId: $captainFplId, ')
          ..write('viceCaptainFplId: $viceCaptainFplId, ')
          ..write('projectedTotalPoints: $projectedTotalPoints, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('projectionRunId: $projectionRunId, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }
}

class $TransferHistoryTableTable extends TransferHistoryTable
    with TableInfo<$TransferHistoryTableTable, TransferHistoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _elementInFplIdMeta = const VerificationMeta(
    'elementInFplId',
  );
  @override
  late final GeneratedColumn<int> elementInFplId = GeneratedColumn<int>(
    'element_in_fpl_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elementInCostTenthsMeta =
      const VerificationMeta('elementInCostTenths');
  @override
  late final GeneratedColumn<int> elementInCostTenths = GeneratedColumn<int>(
    'element_in_cost_tenths',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elementInNameMeta = const VerificationMeta(
    'elementInName',
  );
  @override
  late final GeneratedColumn<String> elementInName = GeneratedColumn<String>(
    'element_in_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elementOutFplIdMeta = const VerificationMeta(
    'elementOutFplId',
  );
  @override
  late final GeneratedColumn<int> elementOutFplId = GeneratedColumn<int>(
    'element_out_fpl_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elementOutCostTenthsMeta =
      const VerificationMeta('elementOutCostTenths');
  @override
  late final GeneratedColumn<int> elementOutCostTenths = GeneratedColumn<int>(
    'element_out_cost_tenths',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elementOutNameMeta = const VerificationMeta(
    'elementOutName',
  );
  @override
  late final GeneratedColumn<String> elementOutName = GeneratedColumn<String>(
    'element_out_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameweekMeta = const VerificationMeta(
    'gameweek',
  );
  @override
  late final GeneratedColumn<int> gameweek = GeneratedColumn<int>(
    'gameweek',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferTimeMeta = const VerificationMeta(
    'transferTime',
  );
  @override
  late final GeneratedColumn<DateTime> transferTime = GeneratedColumn<DateTime>(
    'transfer_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    elementInFplId,
    elementInCostTenths,
    elementInName,
    elementOutFplId,
    elementOutCostTenths,
    elementOutName,
    gameweek,
    transferTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_history_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransferHistoryTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('element_in_fpl_id')) {
      context.handle(
        _elementInFplIdMeta,
        elementInFplId.isAcceptableOrUnknown(
          data['element_in_fpl_id']!,
          _elementInFplIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elementInFplIdMeta);
    }
    if (data.containsKey('element_in_cost_tenths')) {
      context.handle(
        _elementInCostTenthsMeta,
        elementInCostTenths.isAcceptableOrUnknown(
          data['element_in_cost_tenths']!,
          _elementInCostTenthsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elementInCostTenthsMeta);
    }
    if (data.containsKey('element_in_name')) {
      context.handle(
        _elementInNameMeta,
        elementInName.isAcceptableOrUnknown(
          data['element_in_name']!,
          _elementInNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elementInNameMeta);
    }
    if (data.containsKey('element_out_fpl_id')) {
      context.handle(
        _elementOutFplIdMeta,
        elementOutFplId.isAcceptableOrUnknown(
          data['element_out_fpl_id']!,
          _elementOutFplIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elementOutFplIdMeta);
    }
    if (data.containsKey('element_out_cost_tenths')) {
      context.handle(
        _elementOutCostTenthsMeta,
        elementOutCostTenths.isAcceptableOrUnknown(
          data['element_out_cost_tenths']!,
          _elementOutCostTenthsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elementOutCostTenthsMeta);
    }
    if (data.containsKey('element_out_name')) {
      context.handle(
        _elementOutNameMeta,
        elementOutName.isAcceptableOrUnknown(
          data['element_out_name']!,
          _elementOutNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elementOutNameMeta);
    }
    if (data.containsKey('gameweek')) {
      context.handle(
        _gameweekMeta,
        gameweek.isAcceptableOrUnknown(data['gameweek']!, _gameweekMeta),
      );
    } else if (isInserting) {
      context.missing(_gameweekMeta);
    }
    if (data.containsKey('transfer_time')) {
      context.handle(
        _transferTimeMeta,
        transferTime.isAcceptableOrUnknown(
          data['transfer_time']!,
          _transferTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transferTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferHistoryTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferHistoryTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      elementInFplId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}element_in_fpl_id'],
      )!,
      elementInCostTenths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}element_in_cost_tenths'],
      )!,
      elementInName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}element_in_name'],
      )!,
      elementOutFplId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}element_out_fpl_id'],
      )!,
      elementOutCostTenths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}element_out_cost_tenths'],
      )!,
      elementOutName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}element_out_name'],
      )!,
      gameweek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gameweek'],
      )!,
      transferTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transfer_time'],
      )!,
    );
  }

  @override
  $TransferHistoryTableTable createAlias(String alias) {
    return $TransferHistoryTableTable(attachedDatabase, alias);
  }
}

class TransferHistoryTableData extends DataClass
    implements Insertable<TransferHistoryTableData> {
  final int id;
  final int elementInFplId;
  final int elementInCostTenths;
  final String elementInName;
  final int elementOutFplId;
  final int elementOutCostTenths;
  final String elementOutName;
  final int gameweek;
  final DateTime transferTime;
  const TransferHistoryTableData({
    required this.id,
    required this.elementInFplId,
    required this.elementInCostTenths,
    required this.elementInName,
    required this.elementOutFplId,
    required this.elementOutCostTenths,
    required this.elementOutName,
    required this.gameweek,
    required this.transferTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['element_in_fpl_id'] = Variable<int>(elementInFplId);
    map['element_in_cost_tenths'] = Variable<int>(elementInCostTenths);
    map['element_in_name'] = Variable<String>(elementInName);
    map['element_out_fpl_id'] = Variable<int>(elementOutFplId);
    map['element_out_cost_tenths'] = Variable<int>(elementOutCostTenths);
    map['element_out_name'] = Variable<String>(elementOutName);
    map['gameweek'] = Variable<int>(gameweek);
    map['transfer_time'] = Variable<DateTime>(transferTime);
    return map;
  }

  TransferHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return TransferHistoryTableCompanion(
      id: Value(id),
      elementInFplId: Value(elementInFplId),
      elementInCostTenths: Value(elementInCostTenths),
      elementInName: Value(elementInName),
      elementOutFplId: Value(elementOutFplId),
      elementOutCostTenths: Value(elementOutCostTenths),
      elementOutName: Value(elementOutName),
      gameweek: Value(gameweek),
      transferTime: Value(transferTime),
    );
  }

  factory TransferHistoryTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferHistoryTableData(
      id: serializer.fromJson<int>(json['id']),
      elementInFplId: serializer.fromJson<int>(json['elementInFplId']),
      elementInCostTenths: serializer.fromJson<int>(
        json['elementInCostTenths'],
      ),
      elementInName: serializer.fromJson<String>(json['elementInName']),
      elementOutFplId: serializer.fromJson<int>(json['elementOutFplId']),
      elementOutCostTenths: serializer.fromJson<int>(
        json['elementOutCostTenths'],
      ),
      elementOutName: serializer.fromJson<String>(json['elementOutName']),
      gameweek: serializer.fromJson<int>(json['gameweek']),
      transferTime: serializer.fromJson<DateTime>(json['transferTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'elementInFplId': serializer.toJson<int>(elementInFplId),
      'elementInCostTenths': serializer.toJson<int>(elementInCostTenths),
      'elementInName': serializer.toJson<String>(elementInName),
      'elementOutFplId': serializer.toJson<int>(elementOutFplId),
      'elementOutCostTenths': serializer.toJson<int>(elementOutCostTenths),
      'elementOutName': serializer.toJson<String>(elementOutName),
      'gameweek': serializer.toJson<int>(gameweek),
      'transferTime': serializer.toJson<DateTime>(transferTime),
    };
  }

  TransferHistoryTableData copyWith({
    int? id,
    int? elementInFplId,
    int? elementInCostTenths,
    String? elementInName,
    int? elementOutFplId,
    int? elementOutCostTenths,
    String? elementOutName,
    int? gameweek,
    DateTime? transferTime,
  }) => TransferHistoryTableData(
    id: id ?? this.id,
    elementInFplId: elementInFplId ?? this.elementInFplId,
    elementInCostTenths: elementInCostTenths ?? this.elementInCostTenths,
    elementInName: elementInName ?? this.elementInName,
    elementOutFplId: elementOutFplId ?? this.elementOutFplId,
    elementOutCostTenths: elementOutCostTenths ?? this.elementOutCostTenths,
    elementOutName: elementOutName ?? this.elementOutName,
    gameweek: gameweek ?? this.gameweek,
    transferTime: transferTime ?? this.transferTime,
  );
  TransferHistoryTableData copyWithCompanion(
    TransferHistoryTableCompanion data,
  ) {
    return TransferHistoryTableData(
      id: data.id.present ? data.id.value : this.id,
      elementInFplId: data.elementInFplId.present
          ? data.elementInFplId.value
          : this.elementInFplId,
      elementInCostTenths: data.elementInCostTenths.present
          ? data.elementInCostTenths.value
          : this.elementInCostTenths,
      elementInName: data.elementInName.present
          ? data.elementInName.value
          : this.elementInName,
      elementOutFplId: data.elementOutFplId.present
          ? data.elementOutFplId.value
          : this.elementOutFplId,
      elementOutCostTenths: data.elementOutCostTenths.present
          ? data.elementOutCostTenths.value
          : this.elementOutCostTenths,
      elementOutName: data.elementOutName.present
          ? data.elementOutName.value
          : this.elementOutName,
      gameweek: data.gameweek.present ? data.gameweek.value : this.gameweek,
      transferTime: data.transferTime.present
          ? data.transferTime.value
          : this.transferTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferHistoryTableData(')
          ..write('id: $id, ')
          ..write('elementInFplId: $elementInFplId, ')
          ..write('elementInCostTenths: $elementInCostTenths, ')
          ..write('elementInName: $elementInName, ')
          ..write('elementOutFplId: $elementOutFplId, ')
          ..write('elementOutCostTenths: $elementOutCostTenths, ')
          ..write('elementOutName: $elementOutName, ')
          ..write('gameweek: $gameweek, ')
          ..write('transferTime: $transferTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    elementInFplId,
    elementInCostTenths,
    elementInName,
    elementOutFplId,
    elementOutCostTenths,
    elementOutName,
    gameweek,
    transferTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferHistoryTableData &&
          other.id == this.id &&
          other.elementInFplId == this.elementInFplId &&
          other.elementInCostTenths == this.elementInCostTenths &&
          other.elementInName == this.elementInName &&
          other.elementOutFplId == this.elementOutFplId &&
          other.elementOutCostTenths == this.elementOutCostTenths &&
          other.elementOutName == this.elementOutName &&
          other.gameweek == this.gameweek &&
          other.transferTime == this.transferTime);
}

class TransferHistoryTableCompanion
    extends UpdateCompanion<TransferHistoryTableData> {
  final Value<int> id;
  final Value<int> elementInFplId;
  final Value<int> elementInCostTenths;
  final Value<String> elementInName;
  final Value<int> elementOutFplId;
  final Value<int> elementOutCostTenths;
  final Value<String> elementOutName;
  final Value<int> gameweek;
  final Value<DateTime> transferTime;
  const TransferHistoryTableCompanion({
    this.id = const Value.absent(),
    this.elementInFplId = const Value.absent(),
    this.elementInCostTenths = const Value.absent(),
    this.elementInName = const Value.absent(),
    this.elementOutFplId = const Value.absent(),
    this.elementOutCostTenths = const Value.absent(),
    this.elementOutName = const Value.absent(),
    this.gameweek = const Value.absent(),
    this.transferTime = const Value.absent(),
  });
  TransferHistoryTableCompanion.insert({
    this.id = const Value.absent(),
    required int elementInFplId,
    required int elementInCostTenths,
    required String elementInName,
    required int elementOutFplId,
    required int elementOutCostTenths,
    required String elementOutName,
    required int gameweek,
    required DateTime transferTime,
  }) : elementInFplId = Value(elementInFplId),
       elementInCostTenths = Value(elementInCostTenths),
       elementInName = Value(elementInName),
       elementOutFplId = Value(elementOutFplId),
       elementOutCostTenths = Value(elementOutCostTenths),
       elementOutName = Value(elementOutName),
       gameweek = Value(gameweek),
       transferTime = Value(transferTime);
  static Insertable<TransferHistoryTableData> custom({
    Expression<int>? id,
    Expression<int>? elementInFplId,
    Expression<int>? elementInCostTenths,
    Expression<String>? elementInName,
    Expression<int>? elementOutFplId,
    Expression<int>? elementOutCostTenths,
    Expression<String>? elementOutName,
    Expression<int>? gameweek,
    Expression<DateTime>? transferTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (elementInFplId != null) 'element_in_fpl_id': elementInFplId,
      if (elementInCostTenths != null)
        'element_in_cost_tenths': elementInCostTenths,
      if (elementInName != null) 'element_in_name': elementInName,
      if (elementOutFplId != null) 'element_out_fpl_id': elementOutFplId,
      if (elementOutCostTenths != null)
        'element_out_cost_tenths': elementOutCostTenths,
      if (elementOutName != null) 'element_out_name': elementOutName,
      if (gameweek != null) 'gameweek': gameweek,
      if (transferTime != null) 'transfer_time': transferTime,
    });
  }

  TransferHistoryTableCompanion copyWith({
    Value<int>? id,
    Value<int>? elementInFplId,
    Value<int>? elementInCostTenths,
    Value<String>? elementInName,
    Value<int>? elementOutFplId,
    Value<int>? elementOutCostTenths,
    Value<String>? elementOutName,
    Value<int>? gameweek,
    Value<DateTime>? transferTime,
  }) {
    return TransferHistoryTableCompanion(
      id: id ?? this.id,
      elementInFplId: elementInFplId ?? this.elementInFplId,
      elementInCostTenths: elementInCostTenths ?? this.elementInCostTenths,
      elementInName: elementInName ?? this.elementInName,
      elementOutFplId: elementOutFplId ?? this.elementOutFplId,
      elementOutCostTenths: elementOutCostTenths ?? this.elementOutCostTenths,
      elementOutName: elementOutName ?? this.elementOutName,
      gameweek: gameweek ?? this.gameweek,
      transferTime: transferTime ?? this.transferTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (elementInFplId.present) {
      map['element_in_fpl_id'] = Variable<int>(elementInFplId.value);
    }
    if (elementInCostTenths.present) {
      map['element_in_cost_tenths'] = Variable<int>(elementInCostTenths.value);
    }
    if (elementInName.present) {
      map['element_in_name'] = Variable<String>(elementInName.value);
    }
    if (elementOutFplId.present) {
      map['element_out_fpl_id'] = Variable<int>(elementOutFplId.value);
    }
    if (elementOutCostTenths.present) {
      map['element_out_cost_tenths'] = Variable<int>(
        elementOutCostTenths.value,
      );
    }
    if (elementOutName.present) {
      map['element_out_name'] = Variable<String>(elementOutName.value);
    }
    if (gameweek.present) {
      map['gameweek'] = Variable<int>(gameweek.value);
    }
    if (transferTime.present) {
      map['transfer_time'] = Variable<DateTime>(transferTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferHistoryTableCompanion(')
          ..write('id: $id, ')
          ..write('elementInFplId: $elementInFplId, ')
          ..write('elementInCostTenths: $elementInCostTenths, ')
          ..write('elementInName: $elementInName, ')
          ..write('elementOutFplId: $elementOutFplId, ')
          ..write('elementOutCostTenths: $elementOutCostTenths, ')
          ..write('elementOutName: $elementOutName, ')
          ..write('gameweek: $gameweek, ')
          ..write('transferTime: $transferTime')
          ..write(')'))
        .toString();
  }
}

class $GameweekHistoryTableTable extends GameweekHistoryTable
    with TableInfo<$GameweekHistoryTableTable, GameweekHistoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameweekHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _gameweekMeta = const VerificationMeta(
    'gameweek',
  );
  @override
  late final GeneratedColumn<int> gameweek = GeneratedColumn<int>(
    'gameweek',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPointsMeta = const VerificationMeta(
    'totalPoints',
  );
  @override
  late final GeneratedColumn<int> totalPoints = GeneratedColumn<int>(
    'total_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overallRankMeta = const VerificationMeta(
    'overallRank',
  );
  @override
  late final GeneratedColumn<int> overallRank = GeneratedColumn<int>(
    'overall_rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentileRankMeta = const VerificationMeta(
    'percentileRank',
  );
  @override
  late final GeneratedColumn<double> percentileRank = GeneratedColumn<double>(
    'percentile_rank',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventTransfersMeta = const VerificationMeta(
    'eventTransfers',
  );
  @override
  late final GeneratedColumn<int> eventTransfers = GeneratedColumn<int>(
    'event_transfers',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTransfersCostMeta =
      const VerificationMeta('eventTransfersCost');
  @override
  late final GeneratedColumn<int> eventTransfersCost = GeneratedColumn<int>(
    'event_transfers_cost',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointsOnBenchMeta = const VerificationMeta(
    'pointsOnBench',
  );
  @override
  late final GeneratedColumn<int> pointsOnBench = GeneratedColumn<int>(
    'points_on_bench',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankTenthsMeta = const VerificationMeta(
    'bankTenths',
  );
  @override
  late final GeneratedColumn<int> bankTenths = GeneratedColumn<int>(
    'bank_tenths',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueTenthsMeta = const VerificationMeta(
    'valueTenths',
  );
  @override
  late final GeneratedColumn<int> valueTenths = GeneratedColumn<int>(
    'value_tenths',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    gameweek,
    points,
    totalPoints,
    overallRank,
    percentileRank,
    eventTransfers,
    eventTransfersCost,
    pointsOnBench,
    bankTenths,
    valueTenths,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gameweek_history_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameweekHistoryTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('gameweek')) {
      context.handle(
        _gameweekMeta,
        gameweek.isAcceptableOrUnknown(data['gameweek']!, _gameweekMeta),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    } else if (isInserting) {
      context.missing(_pointsMeta);
    }
    if (data.containsKey('total_points')) {
      context.handle(
        _totalPointsMeta,
        totalPoints.isAcceptableOrUnknown(
          data['total_points']!,
          _totalPointsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalPointsMeta);
    }
    if (data.containsKey('overall_rank')) {
      context.handle(
        _overallRankMeta,
        overallRank.isAcceptableOrUnknown(
          data['overall_rank']!,
          _overallRankMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_overallRankMeta);
    }
    if (data.containsKey('percentile_rank')) {
      context.handle(
        _percentileRankMeta,
        percentileRank.isAcceptableOrUnknown(
          data['percentile_rank']!,
          _percentileRankMeta,
        ),
      );
    }
    if (data.containsKey('event_transfers')) {
      context.handle(
        _eventTransfersMeta,
        eventTransfers.isAcceptableOrUnknown(
          data['event_transfers']!,
          _eventTransfersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventTransfersMeta);
    }
    if (data.containsKey('event_transfers_cost')) {
      context.handle(
        _eventTransfersCostMeta,
        eventTransfersCost.isAcceptableOrUnknown(
          data['event_transfers_cost']!,
          _eventTransfersCostMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventTransfersCostMeta);
    }
    if (data.containsKey('points_on_bench')) {
      context.handle(
        _pointsOnBenchMeta,
        pointsOnBench.isAcceptableOrUnknown(
          data['points_on_bench']!,
          _pointsOnBenchMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pointsOnBenchMeta);
    }
    if (data.containsKey('bank_tenths')) {
      context.handle(
        _bankTenthsMeta,
        bankTenths.isAcceptableOrUnknown(data['bank_tenths']!, _bankTenthsMeta),
      );
    } else if (isInserting) {
      context.missing(_bankTenthsMeta);
    }
    if (data.containsKey('value_tenths')) {
      context.handle(
        _valueTenthsMeta,
        valueTenths.isAcceptableOrUnknown(
          data['value_tenths']!,
          _valueTenthsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_valueTenthsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {gameweek};
  @override
  GameweekHistoryTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameweekHistoryTableData(
      gameweek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gameweek'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points'],
      )!,
      totalPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_points'],
      )!,
      overallRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overall_rank'],
      )!,
      percentileRank: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percentile_rank'],
      ),
      eventTransfers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_transfers'],
      )!,
      eventTransfersCost: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_transfers_cost'],
      )!,
      pointsOnBench: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points_on_bench'],
      )!,
      bankTenths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bank_tenths'],
      )!,
      valueTenths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value_tenths'],
      )!,
    );
  }

  @override
  $GameweekHistoryTableTable createAlias(String alias) {
    return $GameweekHistoryTableTable(attachedDatabase, alias);
  }
}

class GameweekHistoryTableData extends DataClass
    implements Insertable<GameweekHistoryTableData> {
  final int gameweek;
  final int points;
  final int totalPoints;
  final int overallRank;
  final double? percentileRank;
  final int eventTransfers;
  final int eventTransfersCost;
  final int pointsOnBench;
  final int bankTenths;
  final int valueTenths;
  const GameweekHistoryTableData({
    required this.gameweek,
    required this.points,
    required this.totalPoints,
    required this.overallRank,
    this.percentileRank,
    required this.eventTransfers,
    required this.eventTransfersCost,
    required this.pointsOnBench,
    required this.bankTenths,
    required this.valueTenths,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['gameweek'] = Variable<int>(gameweek);
    map['points'] = Variable<int>(points);
    map['total_points'] = Variable<int>(totalPoints);
    map['overall_rank'] = Variable<int>(overallRank);
    if (!nullToAbsent || percentileRank != null) {
      map['percentile_rank'] = Variable<double>(percentileRank);
    }
    map['event_transfers'] = Variable<int>(eventTransfers);
    map['event_transfers_cost'] = Variable<int>(eventTransfersCost);
    map['points_on_bench'] = Variable<int>(pointsOnBench);
    map['bank_tenths'] = Variable<int>(bankTenths);
    map['value_tenths'] = Variable<int>(valueTenths);
    return map;
  }

  GameweekHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return GameweekHistoryTableCompanion(
      gameweek: Value(gameweek),
      points: Value(points),
      totalPoints: Value(totalPoints),
      overallRank: Value(overallRank),
      percentileRank: percentileRank == null && nullToAbsent
          ? const Value.absent()
          : Value(percentileRank),
      eventTransfers: Value(eventTransfers),
      eventTransfersCost: Value(eventTransfersCost),
      pointsOnBench: Value(pointsOnBench),
      bankTenths: Value(bankTenths),
      valueTenths: Value(valueTenths),
    );
  }

  factory GameweekHistoryTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameweekHistoryTableData(
      gameweek: serializer.fromJson<int>(json['gameweek']),
      points: serializer.fromJson<int>(json['points']),
      totalPoints: serializer.fromJson<int>(json['totalPoints']),
      overallRank: serializer.fromJson<int>(json['overallRank']),
      percentileRank: serializer.fromJson<double?>(json['percentileRank']),
      eventTransfers: serializer.fromJson<int>(json['eventTransfers']),
      eventTransfersCost: serializer.fromJson<int>(json['eventTransfersCost']),
      pointsOnBench: serializer.fromJson<int>(json['pointsOnBench']),
      bankTenths: serializer.fromJson<int>(json['bankTenths']),
      valueTenths: serializer.fromJson<int>(json['valueTenths']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'gameweek': serializer.toJson<int>(gameweek),
      'points': serializer.toJson<int>(points),
      'totalPoints': serializer.toJson<int>(totalPoints),
      'overallRank': serializer.toJson<int>(overallRank),
      'percentileRank': serializer.toJson<double?>(percentileRank),
      'eventTransfers': serializer.toJson<int>(eventTransfers),
      'eventTransfersCost': serializer.toJson<int>(eventTransfersCost),
      'pointsOnBench': serializer.toJson<int>(pointsOnBench),
      'bankTenths': serializer.toJson<int>(bankTenths),
      'valueTenths': serializer.toJson<int>(valueTenths),
    };
  }

  GameweekHistoryTableData copyWith({
    int? gameweek,
    int? points,
    int? totalPoints,
    int? overallRank,
    Value<double?> percentileRank = const Value.absent(),
    int? eventTransfers,
    int? eventTransfersCost,
    int? pointsOnBench,
    int? bankTenths,
    int? valueTenths,
  }) => GameweekHistoryTableData(
    gameweek: gameweek ?? this.gameweek,
    points: points ?? this.points,
    totalPoints: totalPoints ?? this.totalPoints,
    overallRank: overallRank ?? this.overallRank,
    percentileRank: percentileRank.present
        ? percentileRank.value
        : this.percentileRank,
    eventTransfers: eventTransfers ?? this.eventTransfers,
    eventTransfersCost: eventTransfersCost ?? this.eventTransfersCost,
    pointsOnBench: pointsOnBench ?? this.pointsOnBench,
    bankTenths: bankTenths ?? this.bankTenths,
    valueTenths: valueTenths ?? this.valueTenths,
  );
  GameweekHistoryTableData copyWithCompanion(
    GameweekHistoryTableCompanion data,
  ) {
    return GameweekHistoryTableData(
      gameweek: data.gameweek.present ? data.gameweek.value : this.gameweek,
      points: data.points.present ? data.points.value : this.points,
      totalPoints: data.totalPoints.present
          ? data.totalPoints.value
          : this.totalPoints,
      overallRank: data.overallRank.present
          ? data.overallRank.value
          : this.overallRank,
      percentileRank: data.percentileRank.present
          ? data.percentileRank.value
          : this.percentileRank,
      eventTransfers: data.eventTransfers.present
          ? data.eventTransfers.value
          : this.eventTransfers,
      eventTransfersCost: data.eventTransfersCost.present
          ? data.eventTransfersCost.value
          : this.eventTransfersCost,
      pointsOnBench: data.pointsOnBench.present
          ? data.pointsOnBench.value
          : this.pointsOnBench,
      bankTenths: data.bankTenths.present
          ? data.bankTenths.value
          : this.bankTenths,
      valueTenths: data.valueTenths.present
          ? data.valueTenths.value
          : this.valueTenths,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameweekHistoryTableData(')
          ..write('gameweek: $gameweek, ')
          ..write('points: $points, ')
          ..write('totalPoints: $totalPoints, ')
          ..write('overallRank: $overallRank, ')
          ..write('percentileRank: $percentileRank, ')
          ..write('eventTransfers: $eventTransfers, ')
          ..write('eventTransfersCost: $eventTransfersCost, ')
          ..write('pointsOnBench: $pointsOnBench, ')
          ..write('bankTenths: $bankTenths, ')
          ..write('valueTenths: $valueTenths')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    gameweek,
    points,
    totalPoints,
    overallRank,
    percentileRank,
    eventTransfers,
    eventTransfersCost,
    pointsOnBench,
    bankTenths,
    valueTenths,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameweekHistoryTableData &&
          other.gameweek == this.gameweek &&
          other.points == this.points &&
          other.totalPoints == this.totalPoints &&
          other.overallRank == this.overallRank &&
          other.percentileRank == this.percentileRank &&
          other.eventTransfers == this.eventTransfers &&
          other.eventTransfersCost == this.eventTransfersCost &&
          other.pointsOnBench == this.pointsOnBench &&
          other.bankTenths == this.bankTenths &&
          other.valueTenths == this.valueTenths);
}

class GameweekHistoryTableCompanion
    extends UpdateCompanion<GameweekHistoryTableData> {
  final Value<int> gameweek;
  final Value<int> points;
  final Value<int> totalPoints;
  final Value<int> overallRank;
  final Value<double?> percentileRank;
  final Value<int> eventTransfers;
  final Value<int> eventTransfersCost;
  final Value<int> pointsOnBench;
  final Value<int> bankTenths;
  final Value<int> valueTenths;
  const GameweekHistoryTableCompanion({
    this.gameweek = const Value.absent(),
    this.points = const Value.absent(),
    this.totalPoints = const Value.absent(),
    this.overallRank = const Value.absent(),
    this.percentileRank = const Value.absent(),
    this.eventTransfers = const Value.absent(),
    this.eventTransfersCost = const Value.absent(),
    this.pointsOnBench = const Value.absent(),
    this.bankTenths = const Value.absent(),
    this.valueTenths = const Value.absent(),
  });
  GameweekHistoryTableCompanion.insert({
    this.gameweek = const Value.absent(),
    required int points,
    required int totalPoints,
    required int overallRank,
    this.percentileRank = const Value.absent(),
    required int eventTransfers,
    required int eventTransfersCost,
    required int pointsOnBench,
    required int bankTenths,
    required int valueTenths,
  }) : points = Value(points),
       totalPoints = Value(totalPoints),
       overallRank = Value(overallRank),
       eventTransfers = Value(eventTransfers),
       eventTransfersCost = Value(eventTransfersCost),
       pointsOnBench = Value(pointsOnBench),
       bankTenths = Value(bankTenths),
       valueTenths = Value(valueTenths);
  static Insertable<GameweekHistoryTableData> custom({
    Expression<int>? gameweek,
    Expression<int>? points,
    Expression<int>? totalPoints,
    Expression<int>? overallRank,
    Expression<double>? percentileRank,
    Expression<int>? eventTransfers,
    Expression<int>? eventTransfersCost,
    Expression<int>? pointsOnBench,
    Expression<int>? bankTenths,
    Expression<int>? valueTenths,
  }) {
    return RawValuesInsertable({
      if (gameweek != null) 'gameweek': gameweek,
      if (points != null) 'points': points,
      if (totalPoints != null) 'total_points': totalPoints,
      if (overallRank != null) 'overall_rank': overallRank,
      if (percentileRank != null) 'percentile_rank': percentileRank,
      if (eventTransfers != null) 'event_transfers': eventTransfers,
      if (eventTransfersCost != null)
        'event_transfers_cost': eventTransfersCost,
      if (pointsOnBench != null) 'points_on_bench': pointsOnBench,
      if (bankTenths != null) 'bank_tenths': bankTenths,
      if (valueTenths != null) 'value_tenths': valueTenths,
    });
  }

  GameweekHistoryTableCompanion copyWith({
    Value<int>? gameweek,
    Value<int>? points,
    Value<int>? totalPoints,
    Value<int>? overallRank,
    Value<double?>? percentileRank,
    Value<int>? eventTransfers,
    Value<int>? eventTransfersCost,
    Value<int>? pointsOnBench,
    Value<int>? bankTenths,
    Value<int>? valueTenths,
  }) {
    return GameweekHistoryTableCompanion(
      gameweek: gameweek ?? this.gameweek,
      points: points ?? this.points,
      totalPoints: totalPoints ?? this.totalPoints,
      overallRank: overallRank ?? this.overallRank,
      percentileRank: percentileRank ?? this.percentileRank,
      eventTransfers: eventTransfers ?? this.eventTransfers,
      eventTransfersCost: eventTransfersCost ?? this.eventTransfersCost,
      pointsOnBench: pointsOnBench ?? this.pointsOnBench,
      bankTenths: bankTenths ?? this.bankTenths,
      valueTenths: valueTenths ?? this.valueTenths,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (gameweek.present) {
      map['gameweek'] = Variable<int>(gameweek.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (totalPoints.present) {
      map['total_points'] = Variable<int>(totalPoints.value);
    }
    if (overallRank.present) {
      map['overall_rank'] = Variable<int>(overallRank.value);
    }
    if (percentileRank.present) {
      map['percentile_rank'] = Variable<double>(percentileRank.value);
    }
    if (eventTransfers.present) {
      map['event_transfers'] = Variable<int>(eventTransfers.value);
    }
    if (eventTransfersCost.present) {
      map['event_transfers_cost'] = Variable<int>(eventTransfersCost.value);
    }
    if (pointsOnBench.present) {
      map['points_on_bench'] = Variable<int>(pointsOnBench.value);
    }
    if (bankTenths.present) {
      map['bank_tenths'] = Variable<int>(bankTenths.value);
    }
    if (valueTenths.present) {
      map['value_tenths'] = Variable<int>(valueTenths.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameweekHistoryTableCompanion(')
          ..write('gameweek: $gameweek, ')
          ..write('points: $points, ')
          ..write('totalPoints: $totalPoints, ')
          ..write('overallRank: $overallRank, ')
          ..write('percentileRank: $percentileRank, ')
          ..write('eventTransfers: $eventTransfers, ')
          ..write('eventTransfersCost: $eventTransfersCost, ')
          ..write('pointsOnBench: $pointsOnBench, ')
          ..write('bankTenths: $bankTenths, ')
          ..write('valueTenths: $valueTenths')
          ..write(')'))
        .toString();
  }
}

class $ProjectionBundlesTableTable extends ProjectionBundlesTable
    with TableInfo<$ProjectionBundlesTableTable, ProjectionBundlesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectionBundlesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _gameweekMeta = const VerificationMeta(
    'gameweek',
  );
  @override
  late final GeneratedColumn<int> gameweek = GeneratedColumn<int>(
    'gameweek',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bundleJsonMeta = const VerificationMeta(
    'bundleJson',
  );
  @override
  late final GeneratedColumn<String> bundleJson = GeneratedColumn<String>(
    'bundle_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelVersionMeta = const VerificationMeta(
    'modelVersion',
  );
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
    'model_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    gameweek,
    bundleJson,
    modelVersion,
    publishedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projection_bundles_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectionBundlesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('gameweek')) {
      context.handle(
        _gameweekMeta,
        gameweek.isAcceptableOrUnknown(data['gameweek']!, _gameweekMeta),
      );
    }
    if (data.containsKey('bundle_json')) {
      context.handle(
        _bundleJsonMeta,
        bundleJson.isAcceptableOrUnknown(data['bundle_json']!, _bundleJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_bundleJsonMeta);
    }
    if (data.containsKey('model_version')) {
      context.handle(
        _modelVersionMeta,
        modelVersion.isAcceptableOrUnknown(
          data['model_version']!,
          _modelVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelVersionMeta);
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publishedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {gameweek};
  @override
  ProjectionBundlesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectionBundlesTableData(
      gameweek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gameweek'],
      )!,
      bundleJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bundle_json'],
      )!,
      modelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_version'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $ProjectionBundlesTableTable createAlias(String alias) {
    return $ProjectionBundlesTableTable(attachedDatabase, alias);
  }
}

class ProjectionBundlesTableData extends DataClass
    implements Insertable<ProjectionBundlesTableData> {
  final int gameweek;
  final String bundleJson;
  final String modelVersion;
  final DateTime publishedAt;
  final DateTime cachedAt;
  const ProjectionBundlesTableData({
    required this.gameweek,
    required this.bundleJson,
    required this.modelVersion,
    required this.publishedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['gameweek'] = Variable<int>(gameweek);
    map['bundle_json'] = Variable<String>(bundleJson);
    map['model_version'] = Variable<String>(modelVersion);
    map['published_at'] = Variable<DateTime>(publishedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  ProjectionBundlesTableCompanion toCompanion(bool nullToAbsent) {
    return ProjectionBundlesTableCompanion(
      gameweek: Value(gameweek),
      bundleJson: Value(bundleJson),
      modelVersion: Value(modelVersion),
      publishedAt: Value(publishedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory ProjectionBundlesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectionBundlesTableData(
      gameweek: serializer.fromJson<int>(json['gameweek']),
      bundleJson: serializer.fromJson<String>(json['bundleJson']),
      modelVersion: serializer.fromJson<String>(json['modelVersion']),
      publishedAt: serializer.fromJson<DateTime>(json['publishedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'gameweek': serializer.toJson<int>(gameweek),
      'bundleJson': serializer.toJson<String>(bundleJson),
      'modelVersion': serializer.toJson<String>(modelVersion),
      'publishedAt': serializer.toJson<DateTime>(publishedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  ProjectionBundlesTableData copyWith({
    int? gameweek,
    String? bundleJson,
    String? modelVersion,
    DateTime? publishedAt,
    DateTime? cachedAt,
  }) => ProjectionBundlesTableData(
    gameweek: gameweek ?? this.gameweek,
    bundleJson: bundleJson ?? this.bundleJson,
    modelVersion: modelVersion ?? this.modelVersion,
    publishedAt: publishedAt ?? this.publishedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  ProjectionBundlesTableData copyWithCompanion(
    ProjectionBundlesTableCompanion data,
  ) {
    return ProjectionBundlesTableData(
      gameweek: data.gameweek.present ? data.gameweek.value : this.gameweek,
      bundleJson: data.bundleJson.present
          ? data.bundleJson.value
          : this.bundleJson,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectionBundlesTableData(')
          ..write('gameweek: $gameweek, ')
          ..write('bundleJson: $bundleJson, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(gameweek, bundleJson, modelVersion, publishedAt, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectionBundlesTableData &&
          other.gameweek == this.gameweek &&
          other.bundleJson == this.bundleJson &&
          other.modelVersion == this.modelVersion &&
          other.publishedAt == this.publishedAt &&
          other.cachedAt == this.cachedAt);
}

class ProjectionBundlesTableCompanion
    extends UpdateCompanion<ProjectionBundlesTableData> {
  final Value<int> gameweek;
  final Value<String> bundleJson;
  final Value<String> modelVersion;
  final Value<DateTime> publishedAt;
  final Value<DateTime> cachedAt;
  const ProjectionBundlesTableCompanion({
    this.gameweek = const Value.absent(),
    this.bundleJson = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  ProjectionBundlesTableCompanion.insert({
    this.gameweek = const Value.absent(),
    required String bundleJson,
    required String modelVersion,
    required DateTime publishedAt,
    required DateTime cachedAt,
  }) : bundleJson = Value(bundleJson),
       modelVersion = Value(modelVersion),
       publishedAt = Value(publishedAt),
       cachedAt = Value(cachedAt);
  static Insertable<ProjectionBundlesTableData> custom({
    Expression<int>? gameweek,
    Expression<String>? bundleJson,
    Expression<String>? modelVersion,
    Expression<DateTime>? publishedAt,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (gameweek != null) 'gameweek': gameweek,
      if (bundleJson != null) 'bundle_json': bundleJson,
      if (modelVersion != null) 'model_version': modelVersion,
      if (publishedAt != null) 'published_at': publishedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  ProjectionBundlesTableCompanion copyWith({
    Value<int>? gameweek,
    Value<String>? bundleJson,
    Value<String>? modelVersion,
    Value<DateTime>? publishedAt,
    Value<DateTime>? cachedAt,
  }) {
    return ProjectionBundlesTableCompanion(
      gameweek: gameweek ?? this.gameweek,
      bundleJson: bundleJson ?? this.bundleJson,
      modelVersion: modelVersion ?? this.modelVersion,
      publishedAt: publishedAt ?? this.publishedAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (gameweek.present) {
      map['gameweek'] = Variable<int>(gameweek.value);
    }
    if (bundleJson.present) {
      map['bundle_json'] = Variable<String>(bundleJson.value);
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectionBundlesTableCompanion(')
          ..write('gameweek: $gameweek, ')
          ..write('bundleJson: $bundleJson, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $UserPreferencesTableTable extends UserPreferencesTable
    with TableInfo<$UserPreferencesTableTable, UserPreferencesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferencesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preferences_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPreferencesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  UserPreferencesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreferencesTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $UserPreferencesTableTable createAlias(String alias) {
    return $UserPreferencesTableTable(attachedDatabase, alias);
  }
}

class UserPreferencesTableData extends DataClass
    implements Insertable<UserPreferencesTableData> {
  final String key;
  final String value;
  const UserPreferencesTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  UserPreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return UserPreferencesTableCompanion(key: Value(key), value: Value(value));
  }

  factory UserPreferencesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreferencesTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  UserPreferencesTableData copyWith({String? key, String? value}) =>
      UserPreferencesTableData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  UserPreferencesTableData copyWithCompanion(
    UserPreferencesTableCompanion data,
  ) {
    return UserPreferencesTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesTableData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreferencesTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class UserPreferencesTableCompanion
    extends UpdateCompanion<UserPreferencesTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const UserPreferencesTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserPreferencesTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<UserPreferencesTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserPreferencesTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return UserPreferencesTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SquadPlayersTableTable squadPlayersTable =
      $SquadPlayersTableTable(this);
  late final $PurchasePricesTableTable purchasePricesTable =
      $PurchasePricesTableTable(this);
  late final $LineupResultsTableTable lineupResultsTable =
      $LineupResultsTableTable(this);
  late final $TransferHistoryTableTable transferHistoryTable =
      $TransferHistoryTableTable(this);
  late final $GameweekHistoryTableTable gameweekHistoryTable =
      $GameweekHistoryTableTable(this);
  late final $ProjectionBundlesTableTable projectionBundlesTable =
      $ProjectionBundlesTableTable(this);
  late final $UserPreferencesTableTable userPreferencesTable =
      $UserPreferencesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    squadPlayersTable,
    purchasePricesTable,
    lineupResultsTable,
    transferHistoryTable,
    gameweekHistoryTable,
    projectionBundlesTable,
    userPreferencesTable,
  ];
}

typedef $$SquadPlayersTableTableCreateCompanionBuilder =
    SquadPlayersTableCompanion Function({
      Value<int> id,
      required int fplId,
      required String webName,
      required String position,
      required int teamId,
      required String teamShortName,
      required int purchasePriceTenths,
      required int sellingPriceTenths,
      required int nowCostTenths,
      required String status,
      Value<String?> news,
      Value<int?> chanceOfPlayingNextRound,
      Value<bool> isCaptain,
      Value<bool> isViceCaptain,
      Value<int> multiplier,
      required int positionOrder,
      required String priceSource,
      required DateTime updatedAt,
    });
typedef $$SquadPlayersTableTableUpdateCompanionBuilder =
    SquadPlayersTableCompanion Function({
      Value<int> id,
      Value<int> fplId,
      Value<String> webName,
      Value<String> position,
      Value<int> teamId,
      Value<String> teamShortName,
      Value<int> purchasePriceTenths,
      Value<int> sellingPriceTenths,
      Value<int> nowCostTenths,
      Value<String> status,
      Value<String?> news,
      Value<int?> chanceOfPlayingNextRound,
      Value<bool> isCaptain,
      Value<bool> isViceCaptain,
      Value<int> multiplier,
      Value<int> positionOrder,
      Value<String> priceSource,
      Value<DateTime> updatedAt,
    });

class $$SquadPlayersTableTableFilterComposer
    extends Composer<_$AppDatabase, $SquadPlayersTableTable> {
  $$SquadPlayersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fplId => $composableBuilder(
    column: $table.fplId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get webName => $composableBuilder(
    column: $table.webName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamShortName => $composableBuilder(
    column: $table.teamShortName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purchasePriceTenths => $composableBuilder(
    column: $table.purchasePriceTenths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sellingPriceTenths => $composableBuilder(
    column: $table.sellingPriceTenths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nowCostTenths => $composableBuilder(
    column: $table.nowCostTenths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get news => $composableBuilder(
    column: $table.news,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chanceOfPlayingNextRound => $composableBuilder(
    column: $table.chanceOfPlayingNextRound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCaptain => $composableBuilder(
    column: $table.isCaptain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isViceCaptain => $composableBuilder(
    column: $table.isViceCaptain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get multiplier => $composableBuilder(
    column: $table.multiplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionOrder => $composableBuilder(
    column: $table.positionOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priceSource => $composableBuilder(
    column: $table.priceSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SquadPlayersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SquadPlayersTableTable> {
  $$SquadPlayersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fplId => $composableBuilder(
    column: $table.fplId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get webName => $composableBuilder(
    column: $table.webName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamShortName => $composableBuilder(
    column: $table.teamShortName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purchasePriceTenths => $composableBuilder(
    column: $table.purchasePriceTenths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sellingPriceTenths => $composableBuilder(
    column: $table.sellingPriceTenths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nowCostTenths => $composableBuilder(
    column: $table.nowCostTenths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get news => $composableBuilder(
    column: $table.news,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chanceOfPlayingNextRound => $composableBuilder(
    column: $table.chanceOfPlayingNextRound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCaptain => $composableBuilder(
    column: $table.isCaptain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isViceCaptain => $composableBuilder(
    column: $table.isViceCaptain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get multiplier => $composableBuilder(
    column: $table.multiplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionOrder => $composableBuilder(
    column: $table.positionOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priceSource => $composableBuilder(
    column: $table.priceSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SquadPlayersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SquadPlayersTableTable> {
  $$SquadPlayersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get fplId =>
      $composableBuilder(column: $table.fplId, builder: (column) => column);

  GeneratedColumn<String> get webName =>
      $composableBuilder(column: $table.webName, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get teamShortName => $composableBuilder(
    column: $table.teamShortName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purchasePriceTenths => $composableBuilder(
    column: $table.purchasePriceTenths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sellingPriceTenths => $composableBuilder(
    column: $table.sellingPriceTenths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nowCostTenths => $composableBuilder(
    column: $table.nowCostTenths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get news =>
      $composableBuilder(column: $table.news, builder: (column) => column);

  GeneratedColumn<int> get chanceOfPlayingNextRound => $composableBuilder(
    column: $table.chanceOfPlayingNextRound,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCaptain =>
      $composableBuilder(column: $table.isCaptain, builder: (column) => column);

  GeneratedColumn<bool> get isViceCaptain => $composableBuilder(
    column: $table.isViceCaptain,
    builder: (column) => column,
  );

  GeneratedColumn<int> get multiplier => $composableBuilder(
    column: $table.multiplier,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionOrder => $composableBuilder(
    column: $table.positionOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get priceSource => $composableBuilder(
    column: $table.priceSource,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SquadPlayersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SquadPlayersTableTable,
          SquadPlayersTableData,
          $$SquadPlayersTableTableFilterComposer,
          $$SquadPlayersTableTableOrderingComposer,
          $$SquadPlayersTableTableAnnotationComposer,
          $$SquadPlayersTableTableCreateCompanionBuilder,
          $$SquadPlayersTableTableUpdateCompanionBuilder,
          (
            SquadPlayersTableData,
            BaseReferences<
              _$AppDatabase,
              $SquadPlayersTableTable,
              SquadPlayersTableData
            >,
          ),
          SquadPlayersTableData,
          PrefetchHooks Function()
        > {
  $$SquadPlayersTableTableTableManager(
    _$AppDatabase db,
    $SquadPlayersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SquadPlayersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SquadPlayersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SquadPlayersTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> fplId = const Value.absent(),
                Value<String> webName = const Value.absent(),
                Value<String> position = const Value.absent(),
                Value<int> teamId = const Value.absent(),
                Value<String> teamShortName = const Value.absent(),
                Value<int> purchasePriceTenths = const Value.absent(),
                Value<int> sellingPriceTenths = const Value.absent(),
                Value<int> nowCostTenths = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> news = const Value.absent(),
                Value<int?> chanceOfPlayingNextRound = const Value.absent(),
                Value<bool> isCaptain = const Value.absent(),
                Value<bool> isViceCaptain = const Value.absent(),
                Value<int> multiplier = const Value.absent(),
                Value<int> positionOrder = const Value.absent(),
                Value<String> priceSource = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SquadPlayersTableCompanion(
                id: id,
                fplId: fplId,
                webName: webName,
                position: position,
                teamId: teamId,
                teamShortName: teamShortName,
                purchasePriceTenths: purchasePriceTenths,
                sellingPriceTenths: sellingPriceTenths,
                nowCostTenths: nowCostTenths,
                status: status,
                news: news,
                chanceOfPlayingNextRound: chanceOfPlayingNextRound,
                isCaptain: isCaptain,
                isViceCaptain: isViceCaptain,
                multiplier: multiplier,
                positionOrder: positionOrder,
                priceSource: priceSource,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int fplId,
                required String webName,
                required String position,
                required int teamId,
                required String teamShortName,
                required int purchasePriceTenths,
                required int sellingPriceTenths,
                required int nowCostTenths,
                required String status,
                Value<String?> news = const Value.absent(),
                Value<int?> chanceOfPlayingNextRound = const Value.absent(),
                Value<bool> isCaptain = const Value.absent(),
                Value<bool> isViceCaptain = const Value.absent(),
                Value<int> multiplier = const Value.absent(),
                required int positionOrder,
                required String priceSource,
                required DateTime updatedAt,
              }) => SquadPlayersTableCompanion.insert(
                id: id,
                fplId: fplId,
                webName: webName,
                position: position,
                teamId: teamId,
                teamShortName: teamShortName,
                purchasePriceTenths: purchasePriceTenths,
                sellingPriceTenths: sellingPriceTenths,
                nowCostTenths: nowCostTenths,
                status: status,
                news: news,
                chanceOfPlayingNextRound: chanceOfPlayingNextRound,
                isCaptain: isCaptain,
                isViceCaptain: isViceCaptain,
                multiplier: multiplier,
                positionOrder: positionOrder,
                priceSource: priceSource,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SquadPlayersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SquadPlayersTableTable,
      SquadPlayersTableData,
      $$SquadPlayersTableTableFilterComposer,
      $$SquadPlayersTableTableOrderingComposer,
      $$SquadPlayersTableTableAnnotationComposer,
      $$SquadPlayersTableTableCreateCompanionBuilder,
      $$SquadPlayersTableTableUpdateCompanionBuilder,
      (
        SquadPlayersTableData,
        BaseReferences<
          _$AppDatabase,
          $SquadPlayersTableTable,
          SquadPlayersTableData
        >,
      ),
      SquadPlayersTableData,
      PrefetchHooks Function()
    >;
typedef $$PurchasePricesTableTableCreateCompanionBuilder =
    PurchasePricesTableCompanion Function({
      Value<int> playerFplId,
      required int purchasePriceTenths,
      required String source,
      Value<bool> isConfirmed,
      required DateTime updatedAt,
    });
typedef $$PurchasePricesTableTableUpdateCompanionBuilder =
    PurchasePricesTableCompanion Function({
      Value<int> playerFplId,
      Value<int> purchasePriceTenths,
      Value<String> source,
      Value<bool> isConfirmed,
      Value<DateTime> updatedAt,
    });

class $$PurchasePricesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PurchasePricesTableTable> {
  $$PurchasePricesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get playerFplId => $composableBuilder(
    column: $table.playerFplId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purchasePriceTenths => $composableBuilder(
    column: $table.purchasePriceTenths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isConfirmed => $composableBuilder(
    column: $table.isConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PurchasePricesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchasePricesTableTable> {
  $$PurchasePricesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get playerFplId => $composableBuilder(
    column: $table.playerFplId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purchasePriceTenths => $composableBuilder(
    column: $table.purchasePriceTenths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isConfirmed => $composableBuilder(
    column: $table.isConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PurchasePricesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchasePricesTableTable> {
  $$PurchasePricesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get playerFplId => $composableBuilder(
    column: $table.playerFplId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purchasePriceTenths => $composableBuilder(
    column: $table.purchasePriceTenths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<bool> get isConfirmed => $composableBuilder(
    column: $table.isConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PurchasePricesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchasePricesTableTable,
          PurchasePricesTableData,
          $$PurchasePricesTableTableFilterComposer,
          $$PurchasePricesTableTableOrderingComposer,
          $$PurchasePricesTableTableAnnotationComposer,
          $$PurchasePricesTableTableCreateCompanionBuilder,
          $$PurchasePricesTableTableUpdateCompanionBuilder,
          (
            PurchasePricesTableData,
            BaseReferences<
              _$AppDatabase,
              $PurchasePricesTableTable,
              PurchasePricesTableData
            >,
          ),
          PurchasePricesTableData,
          PrefetchHooks Function()
        > {
  $$PurchasePricesTableTableTableManager(
    _$AppDatabase db,
    $PurchasePricesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchasePricesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchasePricesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PurchasePricesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> playerFplId = const Value.absent(),
                Value<int> purchasePriceTenths = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<bool> isConfirmed = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PurchasePricesTableCompanion(
                playerFplId: playerFplId,
                purchasePriceTenths: purchasePriceTenths,
                source: source,
                isConfirmed: isConfirmed,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> playerFplId = const Value.absent(),
                required int purchasePriceTenths,
                required String source,
                Value<bool> isConfirmed = const Value.absent(),
                required DateTime updatedAt,
              }) => PurchasePricesTableCompanion.insert(
                playerFplId: playerFplId,
                purchasePriceTenths: purchasePriceTenths,
                source: source,
                isConfirmed: isConfirmed,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PurchasePricesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchasePricesTableTable,
      PurchasePricesTableData,
      $$PurchasePricesTableTableFilterComposer,
      $$PurchasePricesTableTableOrderingComposer,
      $$PurchasePricesTableTableAnnotationComposer,
      $$PurchasePricesTableTableCreateCompanionBuilder,
      $$PurchasePricesTableTableUpdateCompanionBuilder,
      (
        PurchasePricesTableData,
        BaseReferences<
          _$AppDatabase,
          $PurchasePricesTableTable,
          PurchasePricesTableData
        >,
      ),
      PurchasePricesTableData,
      PrefetchHooks Function()
    >;
typedef $$LineupResultsTableTableCreateCompanionBuilder =
    LineupResultsTableCompanion Function({
      Value<int> id,
      required int gameweek,
      required String starting11FplIds,
      required String benchFplIds,
      required int captainFplId,
      required int viceCaptainFplId,
      required double projectedTotalPoints,
      required String modelVersion,
      required String projectionRunId,
      required DateTime computedAt,
    });
typedef $$LineupResultsTableTableUpdateCompanionBuilder =
    LineupResultsTableCompanion Function({
      Value<int> id,
      Value<int> gameweek,
      Value<String> starting11FplIds,
      Value<String> benchFplIds,
      Value<int> captainFplId,
      Value<int> viceCaptainFplId,
      Value<double> projectedTotalPoints,
      Value<String> modelVersion,
      Value<String> projectionRunId,
      Value<DateTime> computedAt,
    });

class $$LineupResultsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LineupResultsTableTable> {
  $$LineupResultsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gameweek => $composableBuilder(
    column: $table.gameweek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get starting11FplIds => $composableBuilder(
    column: $table.starting11FplIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get benchFplIds => $composableBuilder(
    column: $table.benchFplIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get captainFplId => $composableBuilder(
    column: $table.captainFplId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get viceCaptainFplId => $composableBuilder(
    column: $table.viceCaptainFplId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get projectedTotalPoints => $composableBuilder(
    column: $table.projectedTotalPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectionRunId => $composableBuilder(
    column: $table.projectionRunId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LineupResultsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LineupResultsTableTable> {
  $$LineupResultsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gameweek => $composableBuilder(
    column: $table.gameweek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get starting11FplIds => $composableBuilder(
    column: $table.starting11FplIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get benchFplIds => $composableBuilder(
    column: $table.benchFplIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get captainFplId => $composableBuilder(
    column: $table.captainFplId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get viceCaptainFplId => $composableBuilder(
    column: $table.viceCaptainFplId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get projectedTotalPoints => $composableBuilder(
    column: $table.projectedTotalPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectionRunId => $composableBuilder(
    column: $table.projectionRunId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LineupResultsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LineupResultsTableTable> {
  $$LineupResultsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get gameweek =>
      $composableBuilder(column: $table.gameweek, builder: (column) => column);

  GeneratedColumn<String> get starting11FplIds => $composableBuilder(
    column: $table.starting11FplIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get benchFplIds => $composableBuilder(
    column: $table.benchFplIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get captainFplId => $composableBuilder(
    column: $table.captainFplId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get viceCaptainFplId => $composableBuilder(
    column: $table.viceCaptainFplId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get projectedTotalPoints => $composableBuilder(
    column: $table.projectedTotalPoints,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectionRunId => $composableBuilder(
    column: $table.projectionRunId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => column,
  );
}

class $$LineupResultsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LineupResultsTableTable,
          LineupResultsTableData,
          $$LineupResultsTableTableFilterComposer,
          $$LineupResultsTableTableOrderingComposer,
          $$LineupResultsTableTableAnnotationComposer,
          $$LineupResultsTableTableCreateCompanionBuilder,
          $$LineupResultsTableTableUpdateCompanionBuilder,
          (
            LineupResultsTableData,
            BaseReferences<
              _$AppDatabase,
              $LineupResultsTableTable,
              LineupResultsTableData
            >,
          ),
          LineupResultsTableData,
          PrefetchHooks Function()
        > {
  $$LineupResultsTableTableTableManager(
    _$AppDatabase db,
    $LineupResultsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LineupResultsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LineupResultsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LineupResultsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameweek = const Value.absent(),
                Value<String> starting11FplIds = const Value.absent(),
                Value<String> benchFplIds = const Value.absent(),
                Value<int> captainFplId = const Value.absent(),
                Value<int> viceCaptainFplId = const Value.absent(),
                Value<double> projectedTotalPoints = const Value.absent(),
                Value<String> modelVersion = const Value.absent(),
                Value<String> projectionRunId = const Value.absent(),
                Value<DateTime> computedAt = const Value.absent(),
              }) => LineupResultsTableCompanion(
                id: id,
                gameweek: gameweek,
                starting11FplIds: starting11FplIds,
                benchFplIds: benchFplIds,
                captainFplId: captainFplId,
                viceCaptainFplId: viceCaptainFplId,
                projectedTotalPoints: projectedTotalPoints,
                modelVersion: modelVersion,
                projectionRunId: projectionRunId,
                computedAt: computedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameweek,
                required String starting11FplIds,
                required String benchFplIds,
                required int captainFplId,
                required int viceCaptainFplId,
                required double projectedTotalPoints,
                required String modelVersion,
                required String projectionRunId,
                required DateTime computedAt,
              }) => LineupResultsTableCompanion.insert(
                id: id,
                gameweek: gameweek,
                starting11FplIds: starting11FplIds,
                benchFplIds: benchFplIds,
                captainFplId: captainFplId,
                viceCaptainFplId: viceCaptainFplId,
                projectedTotalPoints: projectedTotalPoints,
                modelVersion: modelVersion,
                projectionRunId: projectionRunId,
                computedAt: computedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LineupResultsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LineupResultsTableTable,
      LineupResultsTableData,
      $$LineupResultsTableTableFilterComposer,
      $$LineupResultsTableTableOrderingComposer,
      $$LineupResultsTableTableAnnotationComposer,
      $$LineupResultsTableTableCreateCompanionBuilder,
      $$LineupResultsTableTableUpdateCompanionBuilder,
      (
        LineupResultsTableData,
        BaseReferences<
          _$AppDatabase,
          $LineupResultsTableTable,
          LineupResultsTableData
        >,
      ),
      LineupResultsTableData,
      PrefetchHooks Function()
    >;
typedef $$TransferHistoryTableTableCreateCompanionBuilder =
    TransferHistoryTableCompanion Function({
      Value<int> id,
      required int elementInFplId,
      required int elementInCostTenths,
      required String elementInName,
      required int elementOutFplId,
      required int elementOutCostTenths,
      required String elementOutName,
      required int gameweek,
      required DateTime transferTime,
    });
typedef $$TransferHistoryTableTableUpdateCompanionBuilder =
    TransferHistoryTableCompanion Function({
      Value<int> id,
      Value<int> elementInFplId,
      Value<int> elementInCostTenths,
      Value<String> elementInName,
      Value<int> elementOutFplId,
      Value<int> elementOutCostTenths,
      Value<String> elementOutName,
      Value<int> gameweek,
      Value<DateTime> transferTime,
    });

class $$TransferHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $TransferHistoryTableTable> {
  $$TransferHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elementInFplId => $composableBuilder(
    column: $table.elementInFplId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elementInCostTenths => $composableBuilder(
    column: $table.elementInCostTenths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get elementInName => $composableBuilder(
    column: $table.elementInName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elementOutFplId => $composableBuilder(
    column: $table.elementOutFplId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elementOutCostTenths => $composableBuilder(
    column: $table.elementOutCostTenths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get elementOutName => $composableBuilder(
    column: $table.elementOutName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gameweek => $composableBuilder(
    column: $table.gameweek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transferTime => $composableBuilder(
    column: $table.transferTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransferHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferHistoryTableTable> {
  $$TransferHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elementInFplId => $composableBuilder(
    column: $table.elementInFplId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elementInCostTenths => $composableBuilder(
    column: $table.elementInCostTenths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get elementInName => $composableBuilder(
    column: $table.elementInName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elementOutFplId => $composableBuilder(
    column: $table.elementOutFplId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elementOutCostTenths => $composableBuilder(
    column: $table.elementOutCostTenths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get elementOutName => $composableBuilder(
    column: $table.elementOutName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gameweek => $composableBuilder(
    column: $table.gameweek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transferTime => $composableBuilder(
    column: $table.transferTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransferHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferHistoryTableTable> {
  $$TransferHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get elementInFplId => $composableBuilder(
    column: $table.elementInFplId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elementInCostTenths => $composableBuilder(
    column: $table.elementInCostTenths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get elementInName => $composableBuilder(
    column: $table.elementInName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elementOutFplId => $composableBuilder(
    column: $table.elementOutFplId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elementOutCostTenths => $composableBuilder(
    column: $table.elementOutCostTenths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get elementOutName => $composableBuilder(
    column: $table.elementOutName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gameweek =>
      $composableBuilder(column: $table.gameweek, builder: (column) => column);

  GeneratedColumn<DateTime> get transferTime => $composableBuilder(
    column: $table.transferTime,
    builder: (column) => column,
  );
}

class $$TransferHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransferHistoryTableTable,
          TransferHistoryTableData,
          $$TransferHistoryTableTableFilterComposer,
          $$TransferHistoryTableTableOrderingComposer,
          $$TransferHistoryTableTableAnnotationComposer,
          $$TransferHistoryTableTableCreateCompanionBuilder,
          $$TransferHistoryTableTableUpdateCompanionBuilder,
          (
            TransferHistoryTableData,
            BaseReferences<
              _$AppDatabase,
              $TransferHistoryTableTable,
              TransferHistoryTableData
            >,
          ),
          TransferHistoryTableData,
          PrefetchHooks Function()
        > {
  $$TransferHistoryTableTableTableManager(
    _$AppDatabase db,
    $TransferHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferHistoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransferHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> elementInFplId = const Value.absent(),
                Value<int> elementInCostTenths = const Value.absent(),
                Value<String> elementInName = const Value.absent(),
                Value<int> elementOutFplId = const Value.absent(),
                Value<int> elementOutCostTenths = const Value.absent(),
                Value<String> elementOutName = const Value.absent(),
                Value<int> gameweek = const Value.absent(),
                Value<DateTime> transferTime = const Value.absent(),
              }) => TransferHistoryTableCompanion(
                id: id,
                elementInFplId: elementInFplId,
                elementInCostTenths: elementInCostTenths,
                elementInName: elementInName,
                elementOutFplId: elementOutFplId,
                elementOutCostTenths: elementOutCostTenths,
                elementOutName: elementOutName,
                gameweek: gameweek,
                transferTime: transferTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int elementInFplId,
                required int elementInCostTenths,
                required String elementInName,
                required int elementOutFplId,
                required int elementOutCostTenths,
                required String elementOutName,
                required int gameweek,
                required DateTime transferTime,
              }) => TransferHistoryTableCompanion.insert(
                id: id,
                elementInFplId: elementInFplId,
                elementInCostTenths: elementInCostTenths,
                elementInName: elementInName,
                elementOutFplId: elementOutFplId,
                elementOutCostTenths: elementOutCostTenths,
                elementOutName: elementOutName,
                gameweek: gameweek,
                transferTime: transferTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransferHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransferHistoryTableTable,
      TransferHistoryTableData,
      $$TransferHistoryTableTableFilterComposer,
      $$TransferHistoryTableTableOrderingComposer,
      $$TransferHistoryTableTableAnnotationComposer,
      $$TransferHistoryTableTableCreateCompanionBuilder,
      $$TransferHistoryTableTableUpdateCompanionBuilder,
      (
        TransferHistoryTableData,
        BaseReferences<
          _$AppDatabase,
          $TransferHistoryTableTable,
          TransferHistoryTableData
        >,
      ),
      TransferHistoryTableData,
      PrefetchHooks Function()
    >;
typedef $$GameweekHistoryTableTableCreateCompanionBuilder =
    GameweekHistoryTableCompanion Function({
      Value<int> gameweek,
      required int points,
      required int totalPoints,
      required int overallRank,
      Value<double?> percentileRank,
      required int eventTransfers,
      required int eventTransfersCost,
      required int pointsOnBench,
      required int bankTenths,
      required int valueTenths,
    });
typedef $$GameweekHistoryTableTableUpdateCompanionBuilder =
    GameweekHistoryTableCompanion Function({
      Value<int> gameweek,
      Value<int> points,
      Value<int> totalPoints,
      Value<int> overallRank,
      Value<double?> percentileRank,
      Value<int> eventTransfers,
      Value<int> eventTransfersCost,
      Value<int> pointsOnBench,
      Value<int> bankTenths,
      Value<int> valueTenths,
    });

class $$GameweekHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $GameweekHistoryTableTable> {
  $$GameweekHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get gameweek => $composableBuilder(
    column: $table.gameweek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPoints => $composableBuilder(
    column: $table.totalPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overallRank => $composableBuilder(
    column: $table.overallRank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get percentileRank => $composableBuilder(
    column: $table.percentileRank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eventTransfers => $composableBuilder(
    column: $table.eventTransfers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eventTransfersCost => $composableBuilder(
    column: $table.eventTransfersCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pointsOnBench => $composableBuilder(
    column: $table.pointsOnBench,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bankTenths => $composableBuilder(
    column: $table.bankTenths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valueTenths => $composableBuilder(
    column: $table.valueTenths,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GameweekHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GameweekHistoryTableTable> {
  $$GameweekHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get gameweek => $composableBuilder(
    column: $table.gameweek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPoints => $composableBuilder(
    column: $table.totalPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overallRank => $composableBuilder(
    column: $table.overallRank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get percentileRank => $composableBuilder(
    column: $table.percentileRank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eventTransfers => $composableBuilder(
    column: $table.eventTransfers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eventTransfersCost => $composableBuilder(
    column: $table.eventTransfersCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointsOnBench => $composableBuilder(
    column: $table.pointsOnBench,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bankTenths => $composableBuilder(
    column: $table.bankTenths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valueTenths => $composableBuilder(
    column: $table.valueTenths,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GameweekHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameweekHistoryTableTable> {
  $$GameweekHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get gameweek =>
      $composableBuilder(column: $table.gameweek, builder: (column) => column);

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<int> get totalPoints => $composableBuilder(
    column: $table.totalPoints,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overallRank => $composableBuilder(
    column: $table.overallRank,
    builder: (column) => column,
  );

  GeneratedColumn<double> get percentileRank => $composableBuilder(
    column: $table.percentileRank,
    builder: (column) => column,
  );

  GeneratedColumn<int> get eventTransfers => $composableBuilder(
    column: $table.eventTransfers,
    builder: (column) => column,
  );

  GeneratedColumn<int> get eventTransfersCost => $composableBuilder(
    column: $table.eventTransfersCost,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pointsOnBench => $composableBuilder(
    column: $table.pointsOnBench,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bankTenths => $composableBuilder(
    column: $table.bankTenths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get valueTenths => $composableBuilder(
    column: $table.valueTenths,
    builder: (column) => column,
  );
}

class $$GameweekHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GameweekHistoryTableTable,
          GameweekHistoryTableData,
          $$GameweekHistoryTableTableFilterComposer,
          $$GameweekHistoryTableTableOrderingComposer,
          $$GameweekHistoryTableTableAnnotationComposer,
          $$GameweekHistoryTableTableCreateCompanionBuilder,
          $$GameweekHistoryTableTableUpdateCompanionBuilder,
          (
            GameweekHistoryTableData,
            BaseReferences<
              _$AppDatabase,
              $GameweekHistoryTableTable,
              GameweekHistoryTableData
            >,
          ),
          GameweekHistoryTableData,
          PrefetchHooks Function()
        > {
  $$GameweekHistoryTableTableTableManager(
    _$AppDatabase db,
    $GameweekHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameweekHistoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameweekHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GameweekHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> gameweek = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<int> totalPoints = const Value.absent(),
                Value<int> overallRank = const Value.absent(),
                Value<double?> percentileRank = const Value.absent(),
                Value<int> eventTransfers = const Value.absent(),
                Value<int> eventTransfersCost = const Value.absent(),
                Value<int> pointsOnBench = const Value.absent(),
                Value<int> bankTenths = const Value.absent(),
                Value<int> valueTenths = const Value.absent(),
              }) => GameweekHistoryTableCompanion(
                gameweek: gameweek,
                points: points,
                totalPoints: totalPoints,
                overallRank: overallRank,
                percentileRank: percentileRank,
                eventTransfers: eventTransfers,
                eventTransfersCost: eventTransfersCost,
                pointsOnBench: pointsOnBench,
                bankTenths: bankTenths,
                valueTenths: valueTenths,
              ),
          createCompanionCallback:
              ({
                Value<int> gameweek = const Value.absent(),
                required int points,
                required int totalPoints,
                required int overallRank,
                Value<double?> percentileRank = const Value.absent(),
                required int eventTransfers,
                required int eventTransfersCost,
                required int pointsOnBench,
                required int bankTenths,
                required int valueTenths,
              }) => GameweekHistoryTableCompanion.insert(
                gameweek: gameweek,
                points: points,
                totalPoints: totalPoints,
                overallRank: overallRank,
                percentileRank: percentileRank,
                eventTransfers: eventTransfers,
                eventTransfersCost: eventTransfersCost,
                pointsOnBench: pointsOnBench,
                bankTenths: bankTenths,
                valueTenths: valueTenths,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GameweekHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GameweekHistoryTableTable,
      GameweekHistoryTableData,
      $$GameweekHistoryTableTableFilterComposer,
      $$GameweekHistoryTableTableOrderingComposer,
      $$GameweekHistoryTableTableAnnotationComposer,
      $$GameweekHistoryTableTableCreateCompanionBuilder,
      $$GameweekHistoryTableTableUpdateCompanionBuilder,
      (
        GameweekHistoryTableData,
        BaseReferences<
          _$AppDatabase,
          $GameweekHistoryTableTable,
          GameweekHistoryTableData
        >,
      ),
      GameweekHistoryTableData,
      PrefetchHooks Function()
    >;
typedef $$ProjectionBundlesTableTableCreateCompanionBuilder =
    ProjectionBundlesTableCompanion Function({
      Value<int> gameweek,
      required String bundleJson,
      required String modelVersion,
      required DateTime publishedAt,
      required DateTime cachedAt,
    });
typedef $$ProjectionBundlesTableTableUpdateCompanionBuilder =
    ProjectionBundlesTableCompanion Function({
      Value<int> gameweek,
      Value<String> bundleJson,
      Value<String> modelVersion,
      Value<DateTime> publishedAt,
      Value<DateTime> cachedAt,
    });

class $$ProjectionBundlesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectionBundlesTableTable> {
  $$ProjectionBundlesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get gameweek => $composableBuilder(
    column: $table.gameweek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bundleJson => $composableBuilder(
    column: $table.bundleJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectionBundlesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectionBundlesTableTable> {
  $$ProjectionBundlesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get gameweek => $composableBuilder(
    column: $table.gameweek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bundleJson => $composableBuilder(
    column: $table.bundleJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectionBundlesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectionBundlesTableTable> {
  $$ProjectionBundlesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get gameweek =>
      $composableBuilder(column: $table.gameweek, builder: (column) => column);

  GeneratedColumn<String> get bundleJson => $composableBuilder(
    column: $table.bundleJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ProjectionBundlesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectionBundlesTableTable,
          ProjectionBundlesTableData,
          $$ProjectionBundlesTableTableFilterComposer,
          $$ProjectionBundlesTableTableOrderingComposer,
          $$ProjectionBundlesTableTableAnnotationComposer,
          $$ProjectionBundlesTableTableCreateCompanionBuilder,
          $$ProjectionBundlesTableTableUpdateCompanionBuilder,
          (
            ProjectionBundlesTableData,
            BaseReferences<
              _$AppDatabase,
              $ProjectionBundlesTableTable,
              ProjectionBundlesTableData
            >,
          ),
          ProjectionBundlesTableData,
          PrefetchHooks Function()
        > {
  $$ProjectionBundlesTableTableTableManager(
    _$AppDatabase db,
    $ProjectionBundlesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectionBundlesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProjectionBundlesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProjectionBundlesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> gameweek = const Value.absent(),
                Value<String> bundleJson = const Value.absent(),
                Value<String> modelVersion = const Value.absent(),
                Value<DateTime> publishedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => ProjectionBundlesTableCompanion(
                gameweek: gameweek,
                bundleJson: bundleJson,
                modelVersion: modelVersion,
                publishedAt: publishedAt,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> gameweek = const Value.absent(),
                required String bundleJson,
                required String modelVersion,
                required DateTime publishedAt,
                required DateTime cachedAt,
              }) => ProjectionBundlesTableCompanion.insert(
                gameweek: gameweek,
                bundleJson: bundleJson,
                modelVersion: modelVersion,
                publishedAt: publishedAt,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectionBundlesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectionBundlesTableTable,
      ProjectionBundlesTableData,
      $$ProjectionBundlesTableTableFilterComposer,
      $$ProjectionBundlesTableTableOrderingComposer,
      $$ProjectionBundlesTableTableAnnotationComposer,
      $$ProjectionBundlesTableTableCreateCompanionBuilder,
      $$ProjectionBundlesTableTableUpdateCompanionBuilder,
      (
        ProjectionBundlesTableData,
        BaseReferences<
          _$AppDatabase,
          $ProjectionBundlesTableTable,
          ProjectionBundlesTableData
        >,
      ),
      ProjectionBundlesTableData,
      PrefetchHooks Function()
    >;
typedef $$UserPreferencesTableTableCreateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$UserPreferencesTableTableUpdateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$UserPreferencesTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserPreferencesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserPreferencesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$UserPreferencesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserPreferencesTableTable,
          UserPreferencesTableData,
          $$UserPreferencesTableTableFilterComposer,
          $$UserPreferencesTableTableOrderingComposer,
          $$UserPreferencesTableTableAnnotationComposer,
          $$UserPreferencesTableTableCreateCompanionBuilder,
          $$UserPreferencesTableTableUpdateCompanionBuilder,
          (
            UserPreferencesTableData,
            BaseReferences<
              _$AppDatabase,
              $UserPreferencesTableTable,
              UserPreferencesTableData
            >,
          ),
          UserPreferencesTableData,
          PrefetchHooks Function()
        > {
  $$UserPreferencesTableTableTableManager(
    _$AppDatabase db,
    $UserPreferencesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferencesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferencesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserPreferencesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesTableCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserPreferencesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserPreferencesTableTable,
      UserPreferencesTableData,
      $$UserPreferencesTableTableFilterComposer,
      $$UserPreferencesTableTableOrderingComposer,
      $$UserPreferencesTableTableAnnotationComposer,
      $$UserPreferencesTableTableCreateCompanionBuilder,
      $$UserPreferencesTableTableUpdateCompanionBuilder,
      (
        UserPreferencesTableData,
        BaseReferences<
          _$AppDatabase,
          $UserPreferencesTableTable,
          UserPreferencesTableData
        >,
      ),
      UserPreferencesTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SquadPlayersTableTableTableManager get squadPlayersTable =>
      $$SquadPlayersTableTableTableManager(_db, _db.squadPlayersTable);
  $$PurchasePricesTableTableTableManager get purchasePricesTable =>
      $$PurchasePricesTableTableTableManager(_db, _db.purchasePricesTable);
  $$LineupResultsTableTableTableManager get lineupResultsTable =>
      $$LineupResultsTableTableTableManager(_db, _db.lineupResultsTable);
  $$TransferHistoryTableTableTableManager get transferHistoryTable =>
      $$TransferHistoryTableTableTableManager(_db, _db.transferHistoryTable);
  $$GameweekHistoryTableTableTableManager get gameweekHistoryTable =>
      $$GameweekHistoryTableTableTableManager(_db, _db.gameweekHistoryTable);
  $$ProjectionBundlesTableTableTableManager get projectionBundlesTable =>
      $$ProjectionBundlesTableTableTableManager(
        _db,
        _db.projectionBundlesTable,
      );
  $$UserPreferencesTableTableTableManager get userPreferencesTable =>
      $$UserPreferencesTableTableTableManager(_db, _db.userPreferencesTable);
}
