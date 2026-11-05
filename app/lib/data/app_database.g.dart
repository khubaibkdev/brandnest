// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BrandsTable extends Brands with TableInfo<$BrandsTable, Brand> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrandsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta(
    'logoUrl',
  );
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> categories =
      GeneratedColumn<String>(
        'categories',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($BrandsTable.$convertercategories);
  static const VerificationMeta _websiteUrlMeta = const VerificationMeta(
    'websiteUrl',
  );
  @override
  late final GeneratedColumn<String> websiteUrl = GeneratedColumn<String>(
    'website_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    slug,
    name,
    logoUrl,
    categories,
    websiteUrl,
    platform,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'brands';
  @override
  VerificationContext validateIntegrity(
    Insertable<Brand> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('logo_url')) {
      context.handle(
        _logoUrlMeta,
        logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta),
      );
    }
    if (data.containsKey('website_url')) {
      context.handle(
        _websiteUrlMeta,
        websiteUrl.isAcceptableOrUnknown(data['website_url']!, _websiteUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_websiteUrlMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Brand map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Brand(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      logoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_url'],
      ),
      categories: $BrandsTable.$convertercategories.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}categories'],
        )!,
      ),
      websiteUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}website_url'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
    );
  }

  @override
  $BrandsTable createAlias(String alias) {
    return $BrandsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertercategories =
      const StringListConverter();
}

class Brand extends DataClass implements Insertable<Brand> {
  final int id;
  final String slug;
  final String name;
  final String? logoUrl;
  final List<String> categories;
  final String websiteUrl;
  final String platform;
  const Brand({
    required this.id,
    required this.slug,
    required this.name,
    this.logoUrl,
    required this.categories,
    required this.websiteUrl,
    required this.platform,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['slug'] = Variable<String>(slug);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    {
      map['categories'] = Variable<String>(
        $BrandsTable.$convertercategories.toSql(categories),
      );
    }
    map['website_url'] = Variable<String>(websiteUrl);
    map['platform'] = Variable<String>(platform);
    return map;
  }

  BrandsCompanion toCompanion(bool nullToAbsent) {
    return BrandsCompanion(
      id: Value(id),
      slug: Value(slug),
      name: Value(name),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
      categories: Value(categories),
      websiteUrl: Value(websiteUrl),
      platform: Value(platform),
    );
  }

  factory Brand.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Brand(
      id: serializer.fromJson<int>(json['id']),
      slug: serializer.fromJson<String>(json['slug']),
      name: serializer.fromJson<String>(json['name']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      categories: serializer.fromJson<List<String>>(json['categories']),
      websiteUrl: serializer.fromJson<String>(json['websiteUrl']),
      platform: serializer.fromJson<String>(json['platform']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'slug': serializer.toJson<String>(slug),
      'name': serializer.toJson<String>(name),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'categories': serializer.toJson<List<String>>(categories),
      'websiteUrl': serializer.toJson<String>(websiteUrl),
      'platform': serializer.toJson<String>(platform),
    };
  }

  Brand copyWith({
    int? id,
    String? slug,
    String? name,
    Value<String?> logoUrl = const Value.absent(),
    List<String>? categories,
    String? websiteUrl,
    String? platform,
  }) => Brand(
    id: id ?? this.id,
    slug: slug ?? this.slug,
    name: name ?? this.name,
    logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
    categories: categories ?? this.categories,
    websiteUrl: websiteUrl ?? this.websiteUrl,
    platform: platform ?? this.platform,
  );
  Brand copyWithCompanion(BrandsCompanion data) {
    return Brand(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
      name: data.name.present ? data.name.value : this.name,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      categories: data.categories.present
          ? data.categories.value
          : this.categories,
      websiteUrl: data.websiteUrl.present
          ? data.websiteUrl.value
          : this.websiteUrl,
      platform: data.platform.present ? data.platform.value : this.platform,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Brand(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('categories: $categories, ')
          ..write('websiteUrl: $websiteUrl, ')
          ..write('platform: $platform')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, slug, name, logoUrl, categories, websiteUrl, platform);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Brand &&
          other.id == this.id &&
          other.slug == this.slug &&
          other.name == this.name &&
          other.logoUrl == this.logoUrl &&
          other.categories == this.categories &&
          other.websiteUrl == this.websiteUrl &&
          other.platform == this.platform);
}

class BrandsCompanion extends UpdateCompanion<Brand> {
  final Value<int> id;
  final Value<String> slug;
  final Value<String> name;
  final Value<String?> logoUrl;
  final Value<List<String>> categories;
  final Value<String> websiteUrl;
  final Value<String> platform;
  const BrandsCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    this.name = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.categories = const Value.absent(),
    this.websiteUrl = const Value.absent(),
    this.platform = const Value.absent(),
  });
  BrandsCompanion.insert({
    this.id = const Value.absent(),
    required String slug,
    required String name,
    this.logoUrl = const Value.absent(),
    required List<String> categories,
    required String websiteUrl,
    required String platform,
  }) : slug = Value(slug),
       name = Value(name),
       categories = Value(categories),
       websiteUrl = Value(websiteUrl),
       platform = Value(platform);
  static Insertable<Brand> custom({
    Expression<int>? id,
    Expression<String>? slug,
    Expression<String>? name,
    Expression<String>? logoUrl,
    Expression<String>? categories,
    Expression<String>? websiteUrl,
    Expression<String>? platform,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (name != null) 'name': name,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (categories != null) 'categories': categories,
      if (websiteUrl != null) 'website_url': websiteUrl,
      if (platform != null) 'platform': platform,
    });
  }

  BrandsCompanion copyWith({
    Value<int>? id,
    Value<String>? slug,
    Value<String>? name,
    Value<String?>? logoUrl,
    Value<List<String>>? categories,
    Value<String>? websiteUrl,
    Value<String>? platform,
  }) {
    return BrandsCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      categories: categories ?? this.categories,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      platform: platform ?? this.platform,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (categories.present) {
      map['categories'] = Variable<String>(
        $BrandsTable.$convertercategories.toSql(categories.value),
      );
    }
    if (websiteUrl.present) {
      map['website_url'] = Variable<String>(websiteUrl.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrandsCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('categories: $categories, ')
          ..write('websiteUrl: $websiteUrl, ')
          ..write('platform: $platform')
          ..write(')'))
        .toString();
  }
}

class $SaleEventsTable extends SaleEvents
    with TableInfo<$SaleEventsTable, SaleEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandSlugMeta = const VerificationMeta(
    'brandSlug',
  );
  @override
  late final GeneratedColumn<String> brandSlug = GeneratedColumn<String>(
    'brand_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandNameMeta = const VerificationMeta(
    'brandName',
  );
  @override
  late final GeneratedColumn<String> brandName = GeneratedColumn<String>(
    'brand_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountTextMeta = const VerificationMeta(
    'discountText',
  );
  @override
  late final GeneratedColumn<String> discountText = GeneratedColumn<String>(
    'discount_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
    'starts_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<DateTime> endsAt = GeneratedColumn<DateTime>(
    'ends_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  static const VerificationMeta _proofUrlMeta = const VerificationMeta(
    'proofUrl',
  );
  @override
  late final GeneratedColumn<String> proofUrl = GeneratedColumn<String>(
    'proof_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    brandSlug,
    brandName,
    title,
    discountText,
    startsAt,
    endsAt,
    status,
    proofUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('brand_slug')) {
      context.handle(
        _brandSlugMeta,
        brandSlug.isAcceptableOrUnknown(data['brand_slug']!, _brandSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_brandSlugMeta);
    }
    if (data.containsKey('brand_name')) {
      context.handle(
        _brandNameMeta,
        brandName.isAcceptableOrUnknown(data['brand_name']!, _brandNameMeta),
      );
    } else if (isInserting) {
      context.missing(_brandNameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('discount_text')) {
      context.handle(
        _discountTextMeta,
        discountText.isAcceptableOrUnknown(
          data['discount_text']!,
          _discountTextMeta,
        ),
      );
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    }
    if (data.containsKey('ends_at')) {
      context.handle(
        _endsAtMeta,
        endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('proof_url')) {
      context.handle(
        _proofUrlMeta,
        proofUrl.isAcceptableOrUnknown(data['proof_url']!, _proofUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      brandSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_slug'],
      )!,
      brandName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_name'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      discountText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_text'],
      ),
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}starts_at'],
      ),
      endsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ends_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      proofUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proof_url'],
      ),
    );
  }

  @override
  $SaleEventsTable createAlias(String alias) {
    return $SaleEventsTable(attachedDatabase, alias);
  }
}

class SaleEvent extends DataClass implements Insertable<SaleEvent> {
  final int id;
  final String brandSlug;
  final String brandName;
  final String title;
  final String? discountText;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String status;
  final String? proofUrl;
  const SaleEvent({
    required this.id,
    required this.brandSlug,
    required this.brandName,
    required this.title,
    this.discountText,
    this.startsAt,
    this.endsAt,
    required this.status,
    this.proofUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['brand_slug'] = Variable<String>(brandSlug);
    map['brand_name'] = Variable<String>(brandName);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || discountText != null) {
      map['discount_text'] = Variable<String>(discountText);
    }
    if (!nullToAbsent || startsAt != null) {
      map['starts_at'] = Variable<DateTime>(startsAt);
    }
    if (!nullToAbsent || endsAt != null) {
      map['ends_at'] = Variable<DateTime>(endsAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || proofUrl != null) {
      map['proof_url'] = Variable<String>(proofUrl);
    }
    return map;
  }

  SaleEventsCompanion toCompanion(bool nullToAbsent) {
    return SaleEventsCompanion(
      id: Value(id),
      brandSlug: Value(brandSlug),
      brandName: Value(brandName),
      title: Value(title),
      discountText: discountText == null && nullToAbsent
          ? const Value.absent()
          : Value(discountText),
      startsAt: startsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startsAt),
      endsAt: endsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endsAt),
      status: Value(status),
      proofUrl: proofUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(proofUrl),
    );
  }

  factory SaleEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleEvent(
      id: serializer.fromJson<int>(json['id']),
      brandSlug: serializer.fromJson<String>(json['brandSlug']),
      brandName: serializer.fromJson<String>(json['brandName']),
      title: serializer.fromJson<String>(json['title']),
      discountText: serializer.fromJson<String?>(json['discountText']),
      startsAt: serializer.fromJson<DateTime?>(json['startsAt']),
      endsAt: serializer.fromJson<DateTime?>(json['endsAt']),
      status: serializer.fromJson<String>(json['status']),
      proofUrl: serializer.fromJson<String?>(json['proofUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'brandSlug': serializer.toJson<String>(brandSlug),
      'brandName': serializer.toJson<String>(brandName),
      'title': serializer.toJson<String>(title),
      'discountText': serializer.toJson<String?>(discountText),
      'startsAt': serializer.toJson<DateTime?>(startsAt),
      'endsAt': serializer.toJson<DateTime?>(endsAt),
      'status': serializer.toJson<String>(status),
      'proofUrl': serializer.toJson<String?>(proofUrl),
    };
  }

  SaleEvent copyWith({
    int? id,
    String? brandSlug,
    String? brandName,
    String? title,
    Value<String?> discountText = const Value.absent(),
    Value<DateTime?> startsAt = const Value.absent(),
    Value<DateTime?> endsAt = const Value.absent(),
    String? status,
    Value<String?> proofUrl = const Value.absent(),
  }) => SaleEvent(
    id: id ?? this.id,
    brandSlug: brandSlug ?? this.brandSlug,
    brandName: brandName ?? this.brandName,
    title: title ?? this.title,
    discountText: discountText.present ? discountText.value : this.discountText,
    startsAt: startsAt.present ? startsAt.value : this.startsAt,
    endsAt: endsAt.present ? endsAt.value : this.endsAt,
    status: status ?? this.status,
    proofUrl: proofUrl.present ? proofUrl.value : this.proofUrl,
  );
  SaleEvent copyWithCompanion(SaleEventsCompanion data) {
    return SaleEvent(
      id: data.id.present ? data.id.value : this.id,
      brandSlug: data.brandSlug.present ? data.brandSlug.value : this.brandSlug,
      brandName: data.brandName.present ? data.brandName.value : this.brandName,
      title: data.title.present ? data.title.value : this.title,
      discountText: data.discountText.present
          ? data.discountText.value
          : this.discountText,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      status: data.status.present ? data.status.value : this.status,
      proofUrl: data.proofUrl.present ? data.proofUrl.value : this.proofUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleEvent(')
          ..write('id: $id, ')
          ..write('brandSlug: $brandSlug, ')
          ..write('brandName: $brandName, ')
          ..write('title: $title, ')
          ..write('discountText: $discountText, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('status: $status, ')
          ..write('proofUrl: $proofUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    brandSlug,
    brandName,
    title,
    discountText,
    startsAt,
    endsAt,
    status,
    proofUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleEvent &&
          other.id == this.id &&
          other.brandSlug == this.brandSlug &&
          other.brandName == this.brandName &&
          other.title == this.title &&
          other.discountText == this.discountText &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.status == this.status &&
          other.proofUrl == this.proofUrl);
}

class SaleEventsCompanion extends UpdateCompanion<SaleEvent> {
  final Value<int> id;
  final Value<String> brandSlug;
  final Value<String> brandName;
  final Value<String> title;
  final Value<String?> discountText;
  final Value<DateTime?> startsAt;
  final Value<DateTime?> endsAt;
  final Value<String> status;
  final Value<String?> proofUrl;
  const SaleEventsCompanion({
    this.id = const Value.absent(),
    this.brandSlug = const Value.absent(),
    this.brandName = const Value.absent(),
    this.title = const Value.absent(),
    this.discountText = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.status = const Value.absent(),
    this.proofUrl = const Value.absent(),
  });
  SaleEventsCompanion.insert({
    this.id = const Value.absent(),
    required String brandSlug,
    required String brandName,
    required String title,
    this.discountText = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    required String status,
    this.proofUrl = const Value.absent(),
  }) : brandSlug = Value(brandSlug),
       brandName = Value(brandName),
       title = Value(title),
       status = Value(status);
  static Insertable<SaleEvent> custom({
    Expression<int>? id,
    Expression<String>? brandSlug,
    Expression<String>? brandName,
    Expression<String>? title,
    Expression<String>? discountText,
    Expression<DateTime>? startsAt,
    Expression<DateTime>? endsAt,
    Expression<String>? status,
    Expression<String>? proofUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brandSlug != null) 'brand_slug': brandSlug,
      if (brandName != null) 'brand_name': brandName,
      if (title != null) 'title': title,
      if (discountText != null) 'discount_text': discountText,
      if (startsAt != null) 'starts_at': startsAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (status != null) 'status': status,
      if (proofUrl != null) 'proof_url': proofUrl,
    });
  }

  SaleEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? brandSlug,
    Value<String>? brandName,
    Value<String>? title,
    Value<String?>? discountText,
    Value<DateTime?>? startsAt,
    Value<DateTime?>? endsAt,
    Value<String>? status,
    Value<String?>? proofUrl,
  }) {
    return SaleEventsCompanion(
      id: id ?? this.id,
      brandSlug: brandSlug ?? this.brandSlug,
      brandName: brandName ?? this.brandName,
      title: title ?? this.title,
      discountText: discountText ?? this.discountText,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      status: status ?? this.status,
      proofUrl: proofUrl ?? this.proofUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (brandSlug.present) {
      map['brand_slug'] = Variable<String>(brandSlug.value);
    }
    if (brandName.present) {
      map['brand_name'] = Variable<String>(brandName.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (discountText.present) {
      map['discount_text'] = Variable<String>(discountText.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<DateTime>(endsAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (proofUrl.present) {
      map['proof_url'] = Variable<String>(proofUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleEventsCompanion(')
          ..write('id: $id, ')
          ..write('brandSlug: $brandSlug, ')
          ..write('brandName: $brandName, ')
          ..write('title: $title, ')
          ..write('discountText: $discountText, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('status: $status, ')
          ..write('proofUrl: $proofUrl')
          ..write(')'))
        .toString();
  }
}

class $DirectoryOffersTable extends DirectoryOffers
    with TableInfo<$DirectoryOffersTable, DirectoryOffer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DirectoryOffersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bankSlugMeta = const VerificationMeta(
    'bankSlug',
  );
  @override
  late final GeneratedColumn<String> bankSlug = GeneratedColumn<String>(
    'bank_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandSlugMeta = const VerificationMeta(
    'brandSlug',
  );
  @override
  late final GeneratedColumn<String> brandSlug = GeneratedColumn<String>(
    'brand_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandNameMeta = const VerificationMeta(
    'brandName',
  );
  @override
  late final GeneratedColumn<String> brandName = GeneratedColumn<String>(
    'brand_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> cardTypes =
      GeneratedColumn<String>(
        'card_types',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($DirectoryOffersTable.$convertercardTypes);
  static const VerificationMeta _discountPctMeta = const VerificationMeta(
    'discountPct',
  );
  @override
  late final GeneratedColumn<double> discountPct = GeneratedColumn<double>(
    'discount_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxDiscountAmountMeta = const VerificationMeta(
    'maxDiscountAmount',
  );
  @override
  late final GeneratedColumn<double> maxDiscountAmount =
      GeneratedColumn<double>(
        'max_discount_amount',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _minSpendMeta = const VerificationMeta(
    'minSpend',
  );
  @override
  late final GeneratedColumn<double> minSpend = GeneratedColumn<double>(
    'min_spend',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<DateTime> validFrom = GeneratedColumn<DateTime>(
    'valid_from',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validToMeta = const VerificationMeta(
    'validTo',
  );
  @override
  late final GeneratedColumn<DateTime> validTo = GeneratedColumn<DateTime>(
    'valid_to',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proofUrlMeta = const VerificationMeta(
    'proofUrl',
  );
  @override
  late final GeneratedColumn<String> proofUrl = GeneratedColumn<String>(
    'proof_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bankSlug,
    bankName,
    brandSlug,
    brandName,
    cardTypes,
    discountPct,
    maxDiscountAmount,
    minSpend,
    channel,
    validFrom,
    validTo,
    proofUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'directory_offers';
  @override
  VerificationContext validateIntegrity(
    Insertable<DirectoryOffer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bank_slug')) {
      context.handle(
        _bankSlugMeta,
        bankSlug.isAcceptableOrUnknown(data['bank_slug']!, _bankSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_bankSlugMeta);
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bankNameMeta);
    }
    if (data.containsKey('brand_slug')) {
      context.handle(
        _brandSlugMeta,
        brandSlug.isAcceptableOrUnknown(data['brand_slug']!, _brandSlugMeta),
      );
    }
    if (data.containsKey('brand_name')) {
      context.handle(
        _brandNameMeta,
        brandName.isAcceptableOrUnknown(data['brand_name']!, _brandNameMeta),
      );
    }
    if (data.containsKey('discount_pct')) {
      context.handle(
        _discountPctMeta,
        discountPct.isAcceptableOrUnknown(
          data['discount_pct']!,
          _discountPctMeta,
        ),
      );
    }
    if (data.containsKey('max_discount_amount')) {
      context.handle(
        _maxDiscountAmountMeta,
        maxDiscountAmount.isAcceptableOrUnknown(
          data['max_discount_amount']!,
          _maxDiscountAmountMeta,
        ),
      );
    }
    if (data.containsKey('min_spend')) {
      context.handle(
        _minSpendMeta,
        minSpend.isAcceptableOrUnknown(data['min_spend']!, _minSpendMeta),
      );
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    } else if (isInserting) {
      context.missing(_channelMeta);
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    }
    if (data.containsKey('valid_to')) {
      context.handle(
        _validToMeta,
        validTo.isAcceptableOrUnknown(data['valid_to']!, _validToMeta),
      );
    }
    if (data.containsKey('proof_url')) {
      context.handle(
        _proofUrlMeta,
        proofUrl.isAcceptableOrUnknown(data['proof_url']!, _proofUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DirectoryOffer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DirectoryOffer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bankSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_slug'],
      )!,
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      )!,
      brandSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_slug'],
      ),
      brandName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_name'],
      ),
      cardTypes: $DirectoryOffersTable.$convertercardTypes.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}card_types'],
        )!,
      ),
      discountPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_pct'],
      ),
      maxDiscountAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_discount_amount'],
      ),
      minSpend: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_spend'],
      ),
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      )!,
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_from'],
      ),
      validTo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_to'],
      ),
      proofUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proof_url'],
      ),
    );
  }

  @override
  $DirectoryOffersTable createAlias(String alias) {
    return $DirectoryOffersTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertercardTypes =
      const StringListConverter();
}

class DirectoryOffer extends DataClass implements Insertable<DirectoryOffer> {
  final int id;
  final String bankSlug;
  final String bankName;
  final String? brandSlug;
  final String? brandName;
  final List<String> cardTypes;
  final double? discountPct;
  final double? maxDiscountAmount;
  final double? minSpend;
  final String channel;
  final DateTime? validFrom;
  final DateTime? validTo;
  final String? proofUrl;
  const DirectoryOffer({
    required this.id,
    required this.bankSlug,
    required this.bankName,
    this.brandSlug,
    this.brandName,
    required this.cardTypes,
    this.discountPct,
    this.maxDiscountAmount,
    this.minSpend,
    required this.channel,
    this.validFrom,
    this.validTo,
    this.proofUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bank_slug'] = Variable<String>(bankSlug);
    map['bank_name'] = Variable<String>(bankName);
    if (!nullToAbsent || brandSlug != null) {
      map['brand_slug'] = Variable<String>(brandSlug);
    }
    if (!nullToAbsent || brandName != null) {
      map['brand_name'] = Variable<String>(brandName);
    }
    {
      map['card_types'] = Variable<String>(
        $DirectoryOffersTable.$convertercardTypes.toSql(cardTypes),
      );
    }
    if (!nullToAbsent || discountPct != null) {
      map['discount_pct'] = Variable<double>(discountPct);
    }
    if (!nullToAbsent || maxDiscountAmount != null) {
      map['max_discount_amount'] = Variable<double>(maxDiscountAmount);
    }
    if (!nullToAbsent || minSpend != null) {
      map['min_spend'] = Variable<double>(minSpend);
    }
    map['channel'] = Variable<String>(channel);
    if (!nullToAbsent || validFrom != null) {
      map['valid_from'] = Variable<DateTime>(validFrom);
    }
    if (!nullToAbsent || validTo != null) {
      map['valid_to'] = Variable<DateTime>(validTo);
    }
    if (!nullToAbsent || proofUrl != null) {
      map['proof_url'] = Variable<String>(proofUrl);
    }
    return map;
  }

  DirectoryOffersCompanion toCompanion(bool nullToAbsent) {
    return DirectoryOffersCompanion(
      id: Value(id),
      bankSlug: Value(bankSlug),
      bankName: Value(bankName),
      brandSlug: brandSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(brandSlug),
      brandName: brandName == null && nullToAbsent
          ? const Value.absent()
          : Value(brandName),
      cardTypes: Value(cardTypes),
      discountPct: discountPct == null && nullToAbsent
          ? const Value.absent()
          : Value(discountPct),
      maxDiscountAmount: maxDiscountAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(maxDiscountAmount),
      minSpend: minSpend == null && nullToAbsent
          ? const Value.absent()
          : Value(minSpend),
      channel: Value(channel),
      validFrom: validFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(validFrom),
      validTo: validTo == null && nullToAbsent
          ? const Value.absent()
          : Value(validTo),
      proofUrl: proofUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(proofUrl),
    );
  }

  factory DirectoryOffer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DirectoryOffer(
      id: serializer.fromJson<int>(json['id']),
      bankSlug: serializer.fromJson<String>(json['bankSlug']),
      bankName: serializer.fromJson<String>(json['bankName']),
      brandSlug: serializer.fromJson<String?>(json['brandSlug']),
      brandName: serializer.fromJson<String?>(json['brandName']),
      cardTypes: serializer.fromJson<List<String>>(json['cardTypes']),
      discountPct: serializer.fromJson<double?>(json['discountPct']),
      maxDiscountAmount: serializer.fromJson<double?>(
        json['maxDiscountAmount'],
      ),
      minSpend: serializer.fromJson<double?>(json['minSpend']),
      channel: serializer.fromJson<String>(json['channel']),
      validFrom: serializer.fromJson<DateTime?>(json['validFrom']),
      validTo: serializer.fromJson<DateTime?>(json['validTo']),
      proofUrl: serializer.fromJson<String?>(json['proofUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bankSlug': serializer.toJson<String>(bankSlug),
      'bankName': serializer.toJson<String>(bankName),
      'brandSlug': serializer.toJson<String?>(brandSlug),
      'brandName': serializer.toJson<String?>(brandName),
      'cardTypes': serializer.toJson<List<String>>(cardTypes),
      'discountPct': serializer.toJson<double?>(discountPct),
      'maxDiscountAmount': serializer.toJson<double?>(maxDiscountAmount),
      'minSpend': serializer.toJson<double?>(minSpend),
      'channel': serializer.toJson<String>(channel),
      'validFrom': serializer.toJson<DateTime?>(validFrom),
      'validTo': serializer.toJson<DateTime?>(validTo),
      'proofUrl': serializer.toJson<String?>(proofUrl),
    };
  }

  DirectoryOffer copyWith({
    int? id,
    String? bankSlug,
    String? bankName,
    Value<String?> brandSlug = const Value.absent(),
    Value<String?> brandName = const Value.absent(),
    List<String>? cardTypes,
    Value<double?> discountPct = const Value.absent(),
    Value<double?> maxDiscountAmount = const Value.absent(),
    Value<double?> minSpend = const Value.absent(),
    String? channel,
    Value<DateTime?> validFrom = const Value.absent(),
    Value<DateTime?> validTo = const Value.absent(),
    Value<String?> proofUrl = const Value.absent(),
  }) => DirectoryOffer(
    id: id ?? this.id,
    bankSlug: bankSlug ?? this.bankSlug,
    bankName: bankName ?? this.bankName,
    brandSlug: brandSlug.present ? brandSlug.value : this.brandSlug,
    brandName: brandName.present ? brandName.value : this.brandName,
    cardTypes: cardTypes ?? this.cardTypes,
    discountPct: discountPct.present ? discountPct.value : this.discountPct,
    maxDiscountAmount: maxDiscountAmount.present
        ? maxDiscountAmount.value
        : this.maxDiscountAmount,
    minSpend: minSpend.present ? minSpend.value : this.minSpend,
    channel: channel ?? this.channel,
    validFrom: validFrom.present ? validFrom.value : this.validFrom,
    validTo: validTo.present ? validTo.value : this.validTo,
    proofUrl: proofUrl.present ? proofUrl.value : this.proofUrl,
  );
  DirectoryOffer copyWithCompanion(DirectoryOffersCompanion data) {
    return DirectoryOffer(
      id: data.id.present ? data.id.value : this.id,
      bankSlug: data.bankSlug.present ? data.bankSlug.value : this.bankSlug,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      brandSlug: data.brandSlug.present ? data.brandSlug.value : this.brandSlug,
      brandName: data.brandName.present ? data.brandName.value : this.brandName,
      cardTypes: data.cardTypes.present ? data.cardTypes.value : this.cardTypes,
      discountPct: data.discountPct.present
          ? data.discountPct.value
          : this.discountPct,
      maxDiscountAmount: data.maxDiscountAmount.present
          ? data.maxDiscountAmount.value
          : this.maxDiscountAmount,
      minSpend: data.minSpend.present ? data.minSpend.value : this.minSpend,
      channel: data.channel.present ? data.channel.value : this.channel,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      validTo: data.validTo.present ? data.validTo.value : this.validTo,
      proofUrl: data.proofUrl.present ? data.proofUrl.value : this.proofUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DirectoryOffer(')
          ..write('id: $id, ')
          ..write('bankSlug: $bankSlug, ')
          ..write('bankName: $bankName, ')
          ..write('brandSlug: $brandSlug, ')
          ..write('brandName: $brandName, ')
          ..write('cardTypes: $cardTypes, ')
          ..write('discountPct: $discountPct, ')
          ..write('maxDiscountAmount: $maxDiscountAmount, ')
          ..write('minSpend: $minSpend, ')
          ..write('channel: $channel, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('proofUrl: $proofUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bankSlug,
    bankName,
    brandSlug,
    brandName,
    cardTypes,
    discountPct,
    maxDiscountAmount,
    minSpend,
    channel,
    validFrom,
    validTo,
    proofUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DirectoryOffer &&
          other.id == this.id &&
          other.bankSlug == this.bankSlug &&
          other.bankName == this.bankName &&
          other.brandSlug == this.brandSlug &&
          other.brandName == this.brandName &&
          other.cardTypes == this.cardTypes &&
          other.discountPct == this.discountPct &&
          other.maxDiscountAmount == this.maxDiscountAmount &&
          other.minSpend == this.minSpend &&
          other.channel == this.channel &&
          other.validFrom == this.validFrom &&
          other.validTo == this.validTo &&
          other.proofUrl == this.proofUrl);
}

class DirectoryOffersCompanion extends UpdateCompanion<DirectoryOffer> {
  final Value<int> id;
  final Value<String> bankSlug;
  final Value<String> bankName;
  final Value<String?> brandSlug;
  final Value<String?> brandName;
  final Value<List<String>> cardTypes;
  final Value<double?> discountPct;
  final Value<double?> maxDiscountAmount;
  final Value<double?> minSpend;
  final Value<String> channel;
  final Value<DateTime?> validFrom;
  final Value<DateTime?> validTo;
  final Value<String?> proofUrl;
  const DirectoryOffersCompanion({
    this.id = const Value.absent(),
    this.bankSlug = const Value.absent(),
    this.bankName = const Value.absent(),
    this.brandSlug = const Value.absent(),
    this.brandName = const Value.absent(),
    this.cardTypes = const Value.absent(),
    this.discountPct = const Value.absent(),
    this.maxDiscountAmount = const Value.absent(),
    this.minSpend = const Value.absent(),
    this.channel = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validTo = const Value.absent(),
    this.proofUrl = const Value.absent(),
  });
  DirectoryOffersCompanion.insert({
    this.id = const Value.absent(),
    required String bankSlug,
    required String bankName,
    this.brandSlug = const Value.absent(),
    this.brandName = const Value.absent(),
    required List<String> cardTypes,
    this.discountPct = const Value.absent(),
    this.maxDiscountAmount = const Value.absent(),
    this.minSpend = const Value.absent(),
    required String channel,
    this.validFrom = const Value.absent(),
    this.validTo = const Value.absent(),
    this.proofUrl = const Value.absent(),
  }) : bankSlug = Value(bankSlug),
       bankName = Value(bankName),
       cardTypes = Value(cardTypes),
       channel = Value(channel);
  static Insertable<DirectoryOffer> custom({
    Expression<int>? id,
    Expression<String>? bankSlug,
    Expression<String>? bankName,
    Expression<String>? brandSlug,
    Expression<String>? brandName,
    Expression<String>? cardTypes,
    Expression<double>? discountPct,
    Expression<double>? maxDiscountAmount,
    Expression<double>? minSpend,
    Expression<String>? channel,
    Expression<DateTime>? validFrom,
    Expression<DateTime>? validTo,
    Expression<String>? proofUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bankSlug != null) 'bank_slug': bankSlug,
      if (bankName != null) 'bank_name': bankName,
      if (brandSlug != null) 'brand_slug': brandSlug,
      if (brandName != null) 'brand_name': brandName,
      if (cardTypes != null) 'card_types': cardTypes,
      if (discountPct != null) 'discount_pct': discountPct,
      if (maxDiscountAmount != null) 'max_discount_amount': maxDiscountAmount,
      if (minSpend != null) 'min_spend': minSpend,
      if (channel != null) 'channel': channel,
      if (validFrom != null) 'valid_from': validFrom,
      if (validTo != null) 'valid_to': validTo,
      if (proofUrl != null) 'proof_url': proofUrl,
    });
  }

  DirectoryOffersCompanion copyWith({
    Value<int>? id,
    Value<String>? bankSlug,
    Value<String>? bankName,
    Value<String?>? brandSlug,
    Value<String?>? brandName,
    Value<List<String>>? cardTypes,
    Value<double?>? discountPct,
    Value<double?>? maxDiscountAmount,
    Value<double?>? minSpend,
    Value<String>? channel,
    Value<DateTime?>? validFrom,
    Value<DateTime?>? validTo,
    Value<String?>? proofUrl,
  }) {
    return DirectoryOffersCompanion(
      id: id ?? this.id,
      bankSlug: bankSlug ?? this.bankSlug,
      bankName: bankName ?? this.bankName,
      brandSlug: brandSlug ?? this.brandSlug,
      brandName: brandName ?? this.brandName,
      cardTypes: cardTypes ?? this.cardTypes,
      discountPct: discountPct ?? this.discountPct,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      minSpend: minSpend ?? this.minSpend,
      channel: channel ?? this.channel,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      proofUrl: proofUrl ?? this.proofUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bankSlug.present) {
      map['bank_slug'] = Variable<String>(bankSlug.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (brandSlug.present) {
      map['brand_slug'] = Variable<String>(brandSlug.value);
    }
    if (brandName.present) {
      map['brand_name'] = Variable<String>(brandName.value);
    }
    if (cardTypes.present) {
      map['card_types'] = Variable<String>(
        $DirectoryOffersTable.$convertercardTypes.toSql(cardTypes.value),
      );
    }
    if (discountPct.present) {
      map['discount_pct'] = Variable<double>(discountPct.value);
    }
    if (maxDiscountAmount.present) {
      map['max_discount_amount'] = Variable<double>(maxDiscountAmount.value);
    }
    if (minSpend.present) {
      map['min_spend'] = Variable<double>(minSpend.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<DateTime>(validFrom.value);
    }
    if (validTo.present) {
      map['valid_to'] = Variable<DateTime>(validTo.value);
    }
    if (proofUrl.present) {
      map['proof_url'] = Variable<String>(proofUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DirectoryOffersCompanion(')
          ..write('id: $id, ')
          ..write('bankSlug: $bankSlug, ')
          ..write('bankName: $bankName, ')
          ..write('brandSlug: $brandSlug, ')
          ..write('brandName: $brandName, ')
          ..write('cardTypes: $cardTypes, ')
          ..write('discountPct: $discountPct, ')
          ..write('maxDiscountAmount: $maxDiscountAmount, ')
          ..write('minSpend: $minSpend, ')
          ..write('channel: $channel, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('proofUrl: $proofUrl')
          ..write(')'))
        .toString();
  }
}

class $MyCardsTable extends MyCards with TableInfo<$MyCardsTable, MyCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MyCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bankSlugMeta = const VerificationMeta(
    'bankSlug',
  );
  @override
  late final GeneratedColumn<String> bankSlug = GeneratedColumn<String>(
    'bank_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardTypeMeta = const VerificationMeta(
    'cardType',
  );
  @override
  late final GeneratedColumn<String> cardType = GeneratedColumn<String>(
    'card_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [bankSlug, cardType];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'my_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<MyCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bank_slug')) {
      context.handle(
        _bankSlugMeta,
        bankSlug.isAcceptableOrUnknown(data['bank_slug']!, _bankSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_bankSlugMeta);
    }
    if (data.containsKey('card_type')) {
      context.handle(
        _cardTypeMeta,
        cardType.isAcceptableOrUnknown(data['card_type']!, _cardTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_cardTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bankSlug, cardType};
  @override
  MyCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MyCard(
      bankSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_slug'],
      )!,
      cardType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_type'],
      )!,
    );
  }

  @override
  $MyCardsTable createAlias(String alias) {
    return $MyCardsTable(attachedDatabase, alias);
  }
}

class MyCard extends DataClass implements Insertable<MyCard> {
  final String bankSlug;
  final String cardType;
  const MyCard({required this.bankSlug, required this.cardType});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bank_slug'] = Variable<String>(bankSlug);
    map['card_type'] = Variable<String>(cardType);
    return map;
  }

  MyCardsCompanion toCompanion(bool nullToAbsent) {
    return MyCardsCompanion(
      bankSlug: Value(bankSlug),
      cardType: Value(cardType),
    );
  }

  factory MyCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MyCard(
      bankSlug: serializer.fromJson<String>(json['bankSlug']),
      cardType: serializer.fromJson<String>(json['cardType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bankSlug': serializer.toJson<String>(bankSlug),
      'cardType': serializer.toJson<String>(cardType),
    };
  }

  MyCard copyWith({String? bankSlug, String? cardType}) => MyCard(
    bankSlug: bankSlug ?? this.bankSlug,
    cardType: cardType ?? this.cardType,
  );
  MyCard copyWithCompanion(MyCardsCompanion data) {
    return MyCard(
      bankSlug: data.bankSlug.present ? data.bankSlug.value : this.bankSlug,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MyCard(')
          ..write('bankSlug: $bankSlug, ')
          ..write('cardType: $cardType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bankSlug, cardType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MyCard &&
          other.bankSlug == this.bankSlug &&
          other.cardType == this.cardType);
}

class MyCardsCompanion extends UpdateCompanion<MyCard> {
  final Value<String> bankSlug;
  final Value<String> cardType;
  final Value<int> rowid;
  const MyCardsCompanion({
    this.bankSlug = const Value.absent(),
    this.cardType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MyCardsCompanion.insert({
    required String bankSlug,
    required String cardType,
    this.rowid = const Value.absent(),
  }) : bankSlug = Value(bankSlug),
       cardType = Value(cardType);
  static Insertable<MyCard> custom({
    Expression<String>? bankSlug,
    Expression<String>? cardType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bankSlug != null) 'bank_slug': bankSlug,
      if (cardType != null) 'card_type': cardType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MyCardsCompanion copyWith({
    Value<String>? bankSlug,
    Value<String>? cardType,
    Value<int>? rowid,
  }) {
    return MyCardsCompanion(
      bankSlug: bankSlug ?? this.bankSlug,
      cardType: cardType ?? this.cardType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bankSlug.present) {
      map['bank_slug'] = Variable<String>(bankSlug.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<String>(cardType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MyCardsCompanion(')
          ..write('bankSlug: $bankSlug, ')
          ..write('cardType: $cardType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _myCardsDirtyMeta = const VerificationMeta(
    'myCardsDirty',
  );
  @override
  late final GeneratedColumn<bool> myCardsDirty = GeneratedColumn<bool>(
    'my_cards_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("my_cards_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, myCardsDirty];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('my_cards_dirty')) {
      context.handle(
        _myCardsDirtyMeta,
        myCardsDirty.isAcceptableOrUnknown(
          data['my_cards_dirty']!,
          _myCardsDirtyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      myCardsDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}my_cards_dirty'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final int id;
  final bool myCardsDirty;
  const SyncStateData({required this.id, required this.myCardsDirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['my_cards_dirty'] = Variable<bool>(myCardsDirty);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(id: Value(id), myCardsDirty: Value(myCardsDirty));
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      id: serializer.fromJson<int>(json['id']),
      myCardsDirty: serializer.fromJson<bool>(json['myCardsDirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'myCardsDirty': serializer.toJson<bool>(myCardsDirty),
    };
  }

  SyncStateData copyWith({int? id, bool? myCardsDirty}) => SyncStateData(
    id: id ?? this.id,
    myCardsDirty: myCardsDirty ?? this.myCardsDirty,
  );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      id: data.id.present ? data.id.value : this.id,
      myCardsDirty: data.myCardsDirty.present
          ? data.myCardsDirty.value
          : this.myCardsDirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('id: $id, ')
          ..write('myCardsDirty: $myCardsDirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, myCardsDirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.id == this.id &&
          other.myCardsDirty == this.myCardsDirty);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<int> id;
  final Value<bool> myCardsDirty;
  const SyncStateCompanion({
    this.id = const Value.absent(),
    this.myCardsDirty = const Value.absent(),
  });
  SyncStateCompanion.insert({
    this.id = const Value.absent(),
    this.myCardsDirty = const Value.absent(),
  });
  static Insertable<SyncStateData> custom({
    Expression<int>? id,
    Expression<bool>? myCardsDirty,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (myCardsDirty != null) 'my_cards_dirty': myCardsDirty,
    });
  }

  SyncStateCompanion copyWith({Value<int>? id, Value<bool>? myCardsDirty}) {
    return SyncStateCompanion(
      id: id ?? this.id,
      myCardsDirty: myCardsDirty ?? this.myCardsDirty,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (myCardsDirty.present) {
      map['my_cards_dirty'] = Variable<bool>(myCardsDirty.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('id: $id, ')
          ..write('myCardsDirty: $myCardsDirty')
          ..write(')'))
        .toString();
  }
}

class $NotificationPrefsTable extends NotificationPrefs
    with TableInfo<$NotificationPrefsTable, NotificationPref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationPrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salesEnabledMeta = const VerificationMeta(
    'salesEnabled',
  );
  @override
  late final GeneratedColumn<bool> salesEnabled = GeneratedColumn<bool>(
    'sales_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sales_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _offersEnabledMeta = const VerificationMeta(
    'offersEnabled',
  );
  @override
  late final GeneratedColumn<bool> offersEnabled = GeneratedColumn<bool>(
    'offers_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("offers_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, salesEnabled, offersEnabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationPref> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sales_enabled')) {
      context.handle(
        _salesEnabledMeta,
        salesEnabled.isAcceptableOrUnknown(
          data['sales_enabled']!,
          _salesEnabledMeta,
        ),
      );
    }
    if (data.containsKey('offers_enabled')) {
      context.handle(
        _offersEnabledMeta,
        offersEnabled.isAcceptableOrUnknown(
          data['offers_enabled']!,
          _offersEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationPref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationPref(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      salesEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sales_enabled'],
      )!,
      offersEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}offers_enabled'],
      )!,
    );
  }

  @override
  $NotificationPrefsTable createAlias(String alias) {
    return $NotificationPrefsTable(attachedDatabase, alias);
  }
}

class NotificationPref extends DataClass
    implements Insertable<NotificationPref> {
  final int id;
  final bool salesEnabled;
  final bool offersEnabled;
  const NotificationPref({
    required this.id,
    required this.salesEnabled,
    required this.offersEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sales_enabled'] = Variable<bool>(salesEnabled);
    map['offers_enabled'] = Variable<bool>(offersEnabled);
    return map;
  }

  NotificationPrefsCompanion toCompanion(bool nullToAbsent) {
    return NotificationPrefsCompanion(
      id: Value(id),
      salesEnabled: Value(salesEnabled),
      offersEnabled: Value(offersEnabled),
    );
  }

  factory NotificationPref.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationPref(
      id: serializer.fromJson<int>(json['id']),
      salesEnabled: serializer.fromJson<bool>(json['salesEnabled']),
      offersEnabled: serializer.fromJson<bool>(json['offersEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'salesEnabled': serializer.toJson<bool>(salesEnabled),
      'offersEnabled': serializer.toJson<bool>(offersEnabled),
    };
  }

  NotificationPref copyWith({
    int? id,
    bool? salesEnabled,
    bool? offersEnabled,
  }) => NotificationPref(
    id: id ?? this.id,
    salesEnabled: salesEnabled ?? this.salesEnabled,
    offersEnabled: offersEnabled ?? this.offersEnabled,
  );
  NotificationPref copyWithCompanion(NotificationPrefsCompanion data) {
    return NotificationPref(
      id: data.id.present ? data.id.value : this.id,
      salesEnabled: data.salesEnabled.present
          ? data.salesEnabled.value
          : this.salesEnabled,
      offersEnabled: data.offersEnabled.present
          ? data.offersEnabled.value
          : this.offersEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationPref(')
          ..write('id: $id, ')
          ..write('salesEnabled: $salesEnabled, ')
          ..write('offersEnabled: $offersEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, salesEnabled, offersEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationPref &&
          other.id == this.id &&
          other.salesEnabled == this.salesEnabled &&
          other.offersEnabled == this.offersEnabled);
}

class NotificationPrefsCompanion extends UpdateCompanion<NotificationPref> {
  final Value<int> id;
  final Value<bool> salesEnabled;
  final Value<bool> offersEnabled;
  const NotificationPrefsCompanion({
    this.id = const Value.absent(),
    this.salesEnabled = const Value.absent(),
    this.offersEnabled = const Value.absent(),
  });
  NotificationPrefsCompanion.insert({
    this.id = const Value.absent(),
    this.salesEnabled = const Value.absent(),
    this.offersEnabled = const Value.absent(),
  });
  static Insertable<NotificationPref> custom({
    Expression<int>? id,
    Expression<bool>? salesEnabled,
    Expression<bool>? offersEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (salesEnabled != null) 'sales_enabled': salesEnabled,
      if (offersEnabled != null) 'offers_enabled': offersEnabled,
    });
  }

  NotificationPrefsCompanion copyWith({
    Value<int>? id,
    Value<bool>? salesEnabled,
    Value<bool>? offersEnabled,
  }) {
    return NotificationPrefsCompanion(
      id: id ?? this.id,
      salesEnabled: salesEnabled ?? this.salesEnabled,
      offersEnabled: offersEnabled ?? this.offersEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (salesEnabled.present) {
      map['sales_enabled'] = Variable<bool>(salesEnabled.value);
    }
    if (offersEnabled.present) {
      map['offers_enabled'] = Variable<bool>(offersEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationPrefsCompanion(')
          ..write('id: $id, ')
          ..write('salesEnabled: $salesEnabled, ')
          ..write('offersEnabled: $offersEnabled')
          ..write(')'))
        .toString();
  }
}

class $DisplayPrefsTable extends DisplayPrefs
    with TableInfo<$DisplayPrefsTable, DisplayPref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DisplayPrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataSaverMeta = const VerificationMeta(
    'dataSaver',
  );
  @override
  late final GeneratedColumn<bool> dataSaver = GeneratedColumn<bool>(
    'data_saver',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("data_saver" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _darkModeMeta = const VerificationMeta(
    'darkMode',
  );
  @override
  late final GeneratedColumn<bool> darkMode = GeneratedColumn<bool>(
    'dark_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dark_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, dataSaver, darkMode];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'display_prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DisplayPref> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('data_saver')) {
      context.handle(
        _dataSaverMeta,
        dataSaver.isAcceptableOrUnknown(data['data_saver']!, _dataSaverMeta),
      );
    }
    if (data.containsKey('dark_mode')) {
      context.handle(
        _darkModeMeta,
        darkMode.isAcceptableOrUnknown(data['dark_mode']!, _darkModeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DisplayPref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DisplayPref(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dataSaver: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}data_saver'],
      )!,
      darkMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dark_mode'],
      )!,
    );
  }

  @override
  $DisplayPrefsTable createAlias(String alias) {
    return $DisplayPrefsTable(attachedDatabase, alias);
  }
}

class DisplayPref extends DataClass implements Insertable<DisplayPref> {
  final int id;
  final bool dataSaver;
  final bool darkMode;
  const DisplayPref({
    required this.id,
    required this.dataSaver,
    required this.darkMode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['data_saver'] = Variable<bool>(dataSaver);
    map['dark_mode'] = Variable<bool>(darkMode);
    return map;
  }

  DisplayPrefsCompanion toCompanion(bool nullToAbsent) {
    return DisplayPrefsCompanion(
      id: Value(id),
      dataSaver: Value(dataSaver),
      darkMode: Value(darkMode),
    );
  }

  factory DisplayPref.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DisplayPref(
      id: serializer.fromJson<int>(json['id']),
      dataSaver: serializer.fromJson<bool>(json['dataSaver']),
      darkMode: serializer.fromJson<bool>(json['darkMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dataSaver': serializer.toJson<bool>(dataSaver),
      'darkMode': serializer.toJson<bool>(darkMode),
    };
  }

  DisplayPref copyWith({int? id, bool? dataSaver, bool? darkMode}) =>
      DisplayPref(
        id: id ?? this.id,
        dataSaver: dataSaver ?? this.dataSaver,
        darkMode: darkMode ?? this.darkMode,
      );
  DisplayPref copyWithCompanion(DisplayPrefsCompanion data) {
    return DisplayPref(
      id: data.id.present ? data.id.value : this.id,
      dataSaver: data.dataSaver.present ? data.dataSaver.value : this.dataSaver,
      darkMode: data.darkMode.present ? data.darkMode.value : this.darkMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DisplayPref(')
          ..write('id: $id, ')
          ..write('dataSaver: $dataSaver, ')
          ..write('darkMode: $darkMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dataSaver, darkMode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DisplayPref &&
          other.id == this.id &&
          other.dataSaver == this.dataSaver &&
          other.darkMode == this.darkMode);
}

class DisplayPrefsCompanion extends UpdateCompanion<DisplayPref> {
  final Value<int> id;
  final Value<bool> dataSaver;
  final Value<bool> darkMode;
  const DisplayPrefsCompanion({
    this.id = const Value.absent(),
    this.dataSaver = const Value.absent(),
    this.darkMode = const Value.absent(),
  });
  DisplayPrefsCompanion.insert({
    this.id = const Value.absent(),
    this.dataSaver = const Value.absent(),
    this.darkMode = const Value.absent(),
  });
  static Insertable<DisplayPref> custom({
    Expression<int>? id,
    Expression<bool>? dataSaver,
    Expression<bool>? darkMode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dataSaver != null) 'data_saver': dataSaver,
      if (darkMode != null) 'dark_mode': darkMode,
    });
  }

  DisplayPrefsCompanion copyWith({
    Value<int>? id,
    Value<bool>? dataSaver,
    Value<bool>? darkMode,
  }) {
    return DisplayPrefsCompanion(
      id: id ?? this.id,
      dataSaver: dataSaver ?? this.dataSaver,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dataSaver.present) {
      map['data_saver'] = Variable<bool>(dataSaver.value);
    }
    if (darkMode.present) {
      map['dark_mode'] = Variable<bool>(darkMode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DisplayPrefsCompanion(')
          ..write('id: $id, ')
          ..write('dataSaver: $dataSaver, ')
          ..write('darkMode: $darkMode')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BrandsTable brands = $BrandsTable(this);
  late final $SaleEventsTable saleEvents = $SaleEventsTable(this);
  late final $DirectoryOffersTable directoryOffers = $DirectoryOffersTable(
    this,
  );
  late final $MyCardsTable myCards = $MyCardsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $NotificationPrefsTable notificationPrefs =
      $NotificationPrefsTable(this);
  late final $DisplayPrefsTable displayPrefs = $DisplayPrefsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    brands,
    saleEvents,
    directoryOffers,
    myCards,
    syncState,
    notificationPrefs,
    displayPrefs,
  ];
}

typedef $$BrandsTableCreateCompanionBuilder =
    BrandsCompanion Function({
      Value<int> id,
      required String slug,
      required String name,
      Value<String?> logoUrl,
      required List<String> categories,
      required String websiteUrl,
      required String platform,
    });
typedef $$BrandsTableUpdateCompanionBuilder =
    BrandsCompanion Function({
      Value<int> id,
      Value<String> slug,
      Value<String> name,
      Value<String?> logoUrl,
      Value<List<String>> categories,
      Value<String> websiteUrl,
      Value<String> platform,
    });

class $$BrandsTableFilterComposer
    extends Composer<_$AppDatabase, $BrandsTable> {
  $$BrandsTableFilterComposer({
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

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get websiteUrl => $composableBuilder(
    column: $table.websiteUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BrandsTableOrderingComposer
    extends Composer<_$AppDatabase, $BrandsTable> {
  $$BrandsTableOrderingComposer({
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

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get websiteUrl => $composableBuilder(
    column: $table.websiteUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BrandsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrandsTable> {
  $$BrandsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get categories =>
      $composableBuilder(
        column: $table.categories,
        builder: (column) => column,
      );

  GeneratedColumn<String> get websiteUrl => $composableBuilder(
    column: $table.websiteUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);
}

class $$BrandsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BrandsTable,
          Brand,
          $$BrandsTableFilterComposer,
          $$BrandsTableOrderingComposer,
          $$BrandsTableAnnotationComposer,
          $$BrandsTableCreateCompanionBuilder,
          $$BrandsTableUpdateCompanionBuilder,
          (Brand, BaseReferences<_$AppDatabase, $BrandsTable, Brand>),
          Brand,
          PrefetchHooks Function()
        > {
  $$BrandsTableTableManager(_$AppDatabase db, $BrandsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrandsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BrandsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BrandsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<List<String>> categories = const Value.absent(),
                Value<String> websiteUrl = const Value.absent(),
                Value<String> platform = const Value.absent(),
              }) => BrandsCompanion(
                id: id,
                slug: slug,
                name: name,
                logoUrl: logoUrl,
                categories: categories,
                websiteUrl: websiteUrl,
                platform: platform,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String slug,
                required String name,
                Value<String?> logoUrl = const Value.absent(),
                required List<String> categories,
                required String websiteUrl,
                required String platform,
              }) => BrandsCompanion.insert(
                id: id,
                slug: slug,
                name: name,
                logoUrl: logoUrl,
                categories: categories,
                websiteUrl: websiteUrl,
                platform: platform,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BrandsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BrandsTable,
      Brand,
      $$BrandsTableFilterComposer,
      $$BrandsTableOrderingComposer,
      $$BrandsTableAnnotationComposer,
      $$BrandsTableCreateCompanionBuilder,
      $$BrandsTableUpdateCompanionBuilder,
      (Brand, BaseReferences<_$AppDatabase, $BrandsTable, Brand>),
      Brand,
      PrefetchHooks Function()
    >;
typedef $$SaleEventsTableCreateCompanionBuilder =
    SaleEventsCompanion Function({
      Value<int> id,
      required String brandSlug,
      required String brandName,
      required String title,
      Value<String?> discountText,
      Value<DateTime?> startsAt,
      Value<DateTime?> endsAt,
      required String status,
      Value<String?> proofUrl,
    });
typedef $$SaleEventsTableUpdateCompanionBuilder =
    SaleEventsCompanion Function({
      Value<int> id,
      Value<String> brandSlug,
      Value<String> brandName,
      Value<String> title,
      Value<String?> discountText,
      Value<DateTime?> startsAt,
      Value<DateTime?> endsAt,
      Value<String> status,
      Value<String?> proofUrl,
    });

class $$SaleEventsTableFilterComposer
    extends Composer<_$AppDatabase, $SaleEventsTable> {
  $$SaleEventsTableFilterComposer({
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

  ColumnFilters<String> get brandSlug => $composableBuilder(
    column: $table.brandSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountText => $composableBuilder(
    column: $table.discountText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proofUrl => $composableBuilder(
    column: $table.proofUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SaleEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $SaleEventsTable> {
  $$SaleEventsTableOrderingComposer({
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

  ColumnOrderings<String> get brandSlug => $composableBuilder(
    column: $table.brandSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountText => $composableBuilder(
    column: $table.discountText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proofUrl => $composableBuilder(
    column: $table.proofUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SaleEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaleEventsTable> {
  $$SaleEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get brandSlug =>
      $composableBuilder(column: $table.brandSlug, builder: (column) => column);

  GeneratedColumn<String> get brandName =>
      $composableBuilder(column: $table.brandName, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get discountText => $composableBuilder(
    column: $table.discountText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endsAt =>
      $composableBuilder(column: $table.endsAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get proofUrl =>
      $composableBuilder(column: $table.proofUrl, builder: (column) => column);
}

class $$SaleEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaleEventsTable,
          SaleEvent,
          $$SaleEventsTableFilterComposer,
          $$SaleEventsTableOrderingComposer,
          $$SaleEventsTableAnnotationComposer,
          $$SaleEventsTableCreateCompanionBuilder,
          $$SaleEventsTableUpdateCompanionBuilder,
          (
            SaleEvent,
            BaseReferences<_$AppDatabase, $SaleEventsTable, SaleEvent>,
          ),
          SaleEvent,
          PrefetchHooks Function()
        > {
  $$SaleEventsTableTableManager(_$AppDatabase db, $SaleEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaleEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaleEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaleEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> brandSlug = const Value.absent(),
                Value<String> brandName = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> discountText = const Value.absent(),
                Value<DateTime?> startsAt = const Value.absent(),
                Value<DateTime?> endsAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> proofUrl = const Value.absent(),
              }) => SaleEventsCompanion(
                id: id,
                brandSlug: brandSlug,
                brandName: brandName,
                title: title,
                discountText: discountText,
                startsAt: startsAt,
                endsAt: endsAt,
                status: status,
                proofUrl: proofUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String brandSlug,
                required String brandName,
                required String title,
                Value<String?> discountText = const Value.absent(),
                Value<DateTime?> startsAt = const Value.absent(),
                Value<DateTime?> endsAt = const Value.absent(),
                required String status,
                Value<String?> proofUrl = const Value.absent(),
              }) => SaleEventsCompanion.insert(
                id: id,
                brandSlug: brandSlug,
                brandName: brandName,
                title: title,
                discountText: discountText,
                startsAt: startsAt,
                endsAt: endsAt,
                status: status,
                proofUrl: proofUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SaleEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaleEventsTable,
      SaleEvent,
      $$SaleEventsTableFilterComposer,
      $$SaleEventsTableOrderingComposer,
      $$SaleEventsTableAnnotationComposer,
      $$SaleEventsTableCreateCompanionBuilder,
      $$SaleEventsTableUpdateCompanionBuilder,
      (SaleEvent, BaseReferences<_$AppDatabase, $SaleEventsTable, SaleEvent>),
      SaleEvent,
      PrefetchHooks Function()
    >;
typedef $$DirectoryOffersTableCreateCompanionBuilder =
    DirectoryOffersCompanion Function({
      Value<int> id,
      required String bankSlug,
      required String bankName,
      Value<String?> brandSlug,
      Value<String?> brandName,
      required List<String> cardTypes,
      Value<double?> discountPct,
      Value<double?> maxDiscountAmount,
      Value<double?> minSpend,
      required String channel,
      Value<DateTime?> validFrom,
      Value<DateTime?> validTo,
      Value<String?> proofUrl,
    });
typedef $$DirectoryOffersTableUpdateCompanionBuilder =
    DirectoryOffersCompanion Function({
      Value<int> id,
      Value<String> bankSlug,
      Value<String> bankName,
      Value<String?> brandSlug,
      Value<String?> brandName,
      Value<List<String>> cardTypes,
      Value<double?> discountPct,
      Value<double?> maxDiscountAmount,
      Value<double?> minSpend,
      Value<String> channel,
      Value<DateTime?> validFrom,
      Value<DateTime?> validTo,
      Value<String?> proofUrl,
    });

class $$DirectoryOffersTableFilterComposer
    extends Composer<_$AppDatabase, $DirectoryOffersTable> {
  $$DirectoryOffersTableFilterComposer({
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

  ColumnFilters<String> get bankSlug => $composableBuilder(
    column: $table.bankSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandSlug => $composableBuilder(
    column: $table.brandSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get cardTypes => $composableBuilder(
    column: $table.cardTypes,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get discountPct => $composableBuilder(
    column: $table.discountPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxDiscountAmount => $composableBuilder(
    column: $table.maxDiscountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minSpend => $composableBuilder(
    column: $table.minSpend,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proofUrl => $composableBuilder(
    column: $table.proofUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DirectoryOffersTableOrderingComposer
    extends Composer<_$AppDatabase, $DirectoryOffersTable> {
  $$DirectoryOffersTableOrderingComposer({
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

  ColumnOrderings<String> get bankSlug => $composableBuilder(
    column: $table.bankSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandSlug => $composableBuilder(
    column: $table.brandSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardTypes => $composableBuilder(
    column: $table.cardTypes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountPct => $composableBuilder(
    column: $table.discountPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxDiscountAmount => $composableBuilder(
    column: $table.maxDiscountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minSpend => $composableBuilder(
    column: $table.minSpend,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proofUrl => $composableBuilder(
    column: $table.proofUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DirectoryOffersTableAnnotationComposer
    extends Composer<_$AppDatabase, $DirectoryOffersTable> {
  $$DirectoryOffersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bankSlug =>
      $composableBuilder(column: $table.bankSlug, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get brandSlug =>
      $composableBuilder(column: $table.brandSlug, builder: (column) => column);

  GeneratedColumn<String> get brandName =>
      $composableBuilder(column: $table.brandName, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get cardTypes =>
      $composableBuilder(column: $table.cardTypes, builder: (column) => column);

  GeneratedColumn<double> get discountPct => $composableBuilder(
    column: $table.discountPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxDiscountAmount => $composableBuilder(
    column: $table.maxDiscountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minSpend =>
      $composableBuilder(column: $table.minSpend, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<DateTime> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<DateTime> get validTo =>
      $composableBuilder(column: $table.validTo, builder: (column) => column);

  GeneratedColumn<String> get proofUrl =>
      $composableBuilder(column: $table.proofUrl, builder: (column) => column);
}

class $$DirectoryOffersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DirectoryOffersTable,
          DirectoryOffer,
          $$DirectoryOffersTableFilterComposer,
          $$DirectoryOffersTableOrderingComposer,
          $$DirectoryOffersTableAnnotationComposer,
          $$DirectoryOffersTableCreateCompanionBuilder,
          $$DirectoryOffersTableUpdateCompanionBuilder,
          (
            DirectoryOffer,
            BaseReferences<
              _$AppDatabase,
              $DirectoryOffersTable,
              DirectoryOffer
            >,
          ),
          DirectoryOffer,
          PrefetchHooks Function()
        > {
  $$DirectoryOffersTableTableManager(
    _$AppDatabase db,
    $DirectoryOffersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DirectoryOffersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DirectoryOffersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DirectoryOffersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> bankSlug = const Value.absent(),
                Value<String> bankName = const Value.absent(),
                Value<String?> brandSlug = const Value.absent(),
                Value<String?> brandName = const Value.absent(),
                Value<List<String>> cardTypes = const Value.absent(),
                Value<double?> discountPct = const Value.absent(),
                Value<double?> maxDiscountAmount = const Value.absent(),
                Value<double?> minSpend = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<DateTime?> validFrom = const Value.absent(),
                Value<DateTime?> validTo = const Value.absent(),
                Value<String?> proofUrl = const Value.absent(),
              }) => DirectoryOffersCompanion(
                id: id,
                bankSlug: bankSlug,
                bankName: bankName,
                brandSlug: brandSlug,
                brandName: brandName,
                cardTypes: cardTypes,
                discountPct: discountPct,
                maxDiscountAmount: maxDiscountAmount,
                minSpend: minSpend,
                channel: channel,
                validFrom: validFrom,
                validTo: validTo,
                proofUrl: proofUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String bankSlug,
                required String bankName,
                Value<String?> brandSlug = const Value.absent(),
                Value<String?> brandName = const Value.absent(),
                required List<String> cardTypes,
                Value<double?> discountPct = const Value.absent(),
                Value<double?> maxDiscountAmount = const Value.absent(),
                Value<double?> minSpend = const Value.absent(),
                required String channel,
                Value<DateTime?> validFrom = const Value.absent(),
                Value<DateTime?> validTo = const Value.absent(),
                Value<String?> proofUrl = const Value.absent(),
              }) => DirectoryOffersCompanion.insert(
                id: id,
                bankSlug: bankSlug,
                bankName: bankName,
                brandSlug: brandSlug,
                brandName: brandName,
                cardTypes: cardTypes,
                discountPct: discountPct,
                maxDiscountAmount: maxDiscountAmount,
                minSpend: minSpend,
                channel: channel,
                validFrom: validFrom,
                validTo: validTo,
                proofUrl: proofUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DirectoryOffersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DirectoryOffersTable,
      DirectoryOffer,
      $$DirectoryOffersTableFilterComposer,
      $$DirectoryOffersTableOrderingComposer,
      $$DirectoryOffersTableAnnotationComposer,
      $$DirectoryOffersTableCreateCompanionBuilder,
      $$DirectoryOffersTableUpdateCompanionBuilder,
      (
        DirectoryOffer,
        BaseReferences<_$AppDatabase, $DirectoryOffersTable, DirectoryOffer>,
      ),
      DirectoryOffer,
      PrefetchHooks Function()
    >;
typedef $$MyCardsTableCreateCompanionBuilder =
    MyCardsCompanion Function({
      required String bankSlug,
      required String cardType,
      Value<int> rowid,
    });
typedef $$MyCardsTableUpdateCompanionBuilder =
    MyCardsCompanion Function({
      Value<String> bankSlug,
      Value<String> cardType,
      Value<int> rowid,
    });

class $$MyCardsTableFilterComposer
    extends Composer<_$AppDatabase, $MyCardsTable> {
  $$MyCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bankSlug => $composableBuilder(
    column: $table.bankSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MyCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $MyCardsTable> {
  $$MyCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bankSlug => $composableBuilder(
    column: $table.bankSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MyCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MyCardsTable> {
  $$MyCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bankSlug =>
      $composableBuilder(column: $table.bankSlug, builder: (column) => column);

  GeneratedColumn<String> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);
}

class $$MyCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MyCardsTable,
          MyCard,
          $$MyCardsTableFilterComposer,
          $$MyCardsTableOrderingComposer,
          $$MyCardsTableAnnotationComposer,
          $$MyCardsTableCreateCompanionBuilder,
          $$MyCardsTableUpdateCompanionBuilder,
          (MyCard, BaseReferences<_$AppDatabase, $MyCardsTable, MyCard>),
          MyCard,
          PrefetchHooks Function()
        > {
  $$MyCardsTableTableManager(_$AppDatabase db, $MyCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MyCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MyCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MyCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bankSlug = const Value.absent(),
                Value<String> cardType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MyCardsCompanion(
                bankSlug: bankSlug,
                cardType: cardType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bankSlug,
                required String cardType,
                Value<int> rowid = const Value.absent(),
              }) => MyCardsCompanion.insert(
                bankSlug: bankSlug,
                cardType: cardType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MyCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MyCardsTable,
      MyCard,
      $$MyCardsTableFilterComposer,
      $$MyCardsTableOrderingComposer,
      $$MyCardsTableAnnotationComposer,
      $$MyCardsTableCreateCompanionBuilder,
      $$MyCardsTableUpdateCompanionBuilder,
      (MyCard, BaseReferences<_$AppDatabase, $MyCardsTable, MyCard>),
      MyCard,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({Value<int> id, Value<bool> myCardsDirty});
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({Value<int> id, Value<bool> myCardsDirty});

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
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

  ColumnFilters<bool> get myCardsDirty => $composableBuilder(
    column: $table.myCardsDirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
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

  ColumnOrderings<bool> get myCardsDirty => $composableBuilder(
    column: $table.myCardsDirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get myCardsDirty => $composableBuilder(
    column: $table.myCardsDirty,
    builder: (column) => column,
  );
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateData,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateData,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
          ),
          SyncStateData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> myCardsDirty = const Value.absent(),
              }) => SyncStateCompanion(id: id, myCardsDirty: myCardsDirty),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> myCardsDirty = const Value.absent(),
              }) =>
                  SyncStateCompanion.insert(id: id, myCardsDirty: myCardsDirty),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateData,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateData,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
      ),
      SyncStateData,
      PrefetchHooks Function()
    >;
typedef $$NotificationPrefsTableCreateCompanionBuilder =
    NotificationPrefsCompanion Function({
      Value<int> id,
      Value<bool> salesEnabled,
      Value<bool> offersEnabled,
    });
typedef $$NotificationPrefsTableUpdateCompanionBuilder =
    NotificationPrefsCompanion Function({
      Value<int> id,
      Value<bool> salesEnabled,
      Value<bool> offersEnabled,
    });

class $$NotificationPrefsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationPrefsTable> {
  $$NotificationPrefsTableFilterComposer({
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

  ColumnFilters<bool> get salesEnabled => $composableBuilder(
    column: $table.salesEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get offersEnabled => $composableBuilder(
    column: $table.offersEnabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationPrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationPrefsTable> {
  $$NotificationPrefsTableOrderingComposer({
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

  ColumnOrderings<bool> get salesEnabled => $composableBuilder(
    column: $table.salesEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get offersEnabled => $composableBuilder(
    column: $table.offersEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationPrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationPrefsTable> {
  $$NotificationPrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get salesEnabled => $composableBuilder(
    column: $table.salesEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get offersEnabled => $composableBuilder(
    column: $table.offersEnabled,
    builder: (column) => column,
  );
}

class $$NotificationPrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationPrefsTable,
          NotificationPref,
          $$NotificationPrefsTableFilterComposer,
          $$NotificationPrefsTableOrderingComposer,
          $$NotificationPrefsTableAnnotationComposer,
          $$NotificationPrefsTableCreateCompanionBuilder,
          $$NotificationPrefsTableUpdateCompanionBuilder,
          (
            NotificationPref,
            BaseReferences<
              _$AppDatabase,
              $NotificationPrefsTable,
              NotificationPref
            >,
          ),
          NotificationPref,
          PrefetchHooks Function()
        > {
  $$NotificationPrefsTableTableManager(
    _$AppDatabase db,
    $NotificationPrefsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationPrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationPrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationPrefsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> salesEnabled = const Value.absent(),
                Value<bool> offersEnabled = const Value.absent(),
              }) => NotificationPrefsCompanion(
                id: id,
                salesEnabled: salesEnabled,
                offersEnabled: offersEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> salesEnabled = const Value.absent(),
                Value<bool> offersEnabled = const Value.absent(),
              }) => NotificationPrefsCompanion.insert(
                id: id,
                salesEnabled: salesEnabled,
                offersEnabled: offersEnabled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationPrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationPrefsTable,
      NotificationPref,
      $$NotificationPrefsTableFilterComposer,
      $$NotificationPrefsTableOrderingComposer,
      $$NotificationPrefsTableAnnotationComposer,
      $$NotificationPrefsTableCreateCompanionBuilder,
      $$NotificationPrefsTableUpdateCompanionBuilder,
      (
        NotificationPref,
        BaseReferences<
          _$AppDatabase,
          $NotificationPrefsTable,
          NotificationPref
        >,
      ),
      NotificationPref,
      PrefetchHooks Function()
    >;
typedef $$DisplayPrefsTableCreateCompanionBuilder =
    DisplayPrefsCompanion Function({
      Value<int> id,
      Value<bool> dataSaver,
      Value<bool> darkMode,
    });
typedef $$DisplayPrefsTableUpdateCompanionBuilder =
    DisplayPrefsCompanion Function({
      Value<int> id,
      Value<bool> dataSaver,
      Value<bool> darkMode,
    });

class $$DisplayPrefsTableFilterComposer
    extends Composer<_$AppDatabase, $DisplayPrefsTable> {
  $$DisplayPrefsTableFilterComposer({
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

  ColumnFilters<bool> get dataSaver => $composableBuilder(
    column: $table.dataSaver,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get darkMode => $composableBuilder(
    column: $table.darkMode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DisplayPrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $DisplayPrefsTable> {
  $$DisplayPrefsTableOrderingComposer({
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

  ColumnOrderings<bool> get dataSaver => $composableBuilder(
    column: $table.dataSaver,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get darkMode => $composableBuilder(
    column: $table.darkMode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DisplayPrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DisplayPrefsTable> {
  $$DisplayPrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get dataSaver =>
      $composableBuilder(column: $table.dataSaver, builder: (column) => column);

  GeneratedColumn<bool> get darkMode =>
      $composableBuilder(column: $table.darkMode, builder: (column) => column);
}

class $$DisplayPrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DisplayPrefsTable,
          DisplayPref,
          $$DisplayPrefsTableFilterComposer,
          $$DisplayPrefsTableOrderingComposer,
          $$DisplayPrefsTableAnnotationComposer,
          $$DisplayPrefsTableCreateCompanionBuilder,
          $$DisplayPrefsTableUpdateCompanionBuilder,
          (
            DisplayPref,
            BaseReferences<_$AppDatabase, $DisplayPrefsTable, DisplayPref>,
          ),
          DisplayPref,
          PrefetchHooks Function()
        > {
  $$DisplayPrefsTableTableManager(_$AppDatabase db, $DisplayPrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DisplayPrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DisplayPrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DisplayPrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> dataSaver = const Value.absent(),
                Value<bool> darkMode = const Value.absent(),
              }) => DisplayPrefsCompanion(
                id: id,
                dataSaver: dataSaver,
                darkMode: darkMode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> dataSaver = const Value.absent(),
                Value<bool> darkMode = const Value.absent(),
              }) => DisplayPrefsCompanion.insert(
                id: id,
                dataSaver: dataSaver,
                darkMode: darkMode,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DisplayPrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DisplayPrefsTable,
      DisplayPref,
      $$DisplayPrefsTableFilterComposer,
      $$DisplayPrefsTableOrderingComposer,
      $$DisplayPrefsTableAnnotationComposer,
      $$DisplayPrefsTableCreateCompanionBuilder,
      $$DisplayPrefsTableUpdateCompanionBuilder,
      (
        DisplayPref,
        BaseReferences<_$AppDatabase, $DisplayPrefsTable, DisplayPref>,
      ),
      DisplayPref,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BrandsTableTableManager get brands =>
      $$BrandsTableTableManager(_db, _db.brands);
  $$SaleEventsTableTableManager get saleEvents =>
      $$SaleEventsTableTableManager(_db, _db.saleEvents);
  $$DirectoryOffersTableTableManager get directoryOffers =>
      $$DirectoryOffersTableTableManager(_db, _db.directoryOffers);
  $$MyCardsTableTableManager get myCards =>
      $$MyCardsTableTableManager(_db, _db.myCards);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$NotificationPrefsTableTableManager get notificationPrefs =>
      $$NotificationPrefsTableTableManager(_db, _db.notificationPrefs);
  $$DisplayPrefsTableTableManager get displayPrefs =>
      $$DisplayPrefsTableTableManager(_db, _db.displayPrefs);
}
