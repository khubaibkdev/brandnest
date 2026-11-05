import 'package:brandnest/data/bank_offer.dart';

/// Shape mirrors `GET /sales` (see backend/app/api/sales.py).
const salesJson = <Map<String, dynamic>>[
  {
    'id': 3,
    'brand_slug': 'outfitters',
    'brand_name': 'Outfitters',
    'title': 'Summer Sale',
    'discount_text': 'Up to 50% off',
    'starts_at': null,
    'ends_at': null,
    'status': 'live',
    'proof_url': 'https://outfitters.com.pk',
  },
  {
    'id': 5,
    'brand_slug': 'limelight',
    'brand_name': 'Limelight',
    'title': 'Azadi Sale',
    'discount_text': 'Flat 30% off',
    'starts_at': '2026-08-10T19:00:00+00:00',
    'ends_at': '2026-08-16T18:59:00+00:00',
    'status': 'verified',
    'proof_url': 'https://limelight.pk',
  },
];

/// Shape mirrors `GET /brands/{slug}/offers` (see backend/app/api/offers.py).
/// Brand-scoped, so no brand fields — the brand asked for is the answer.
const offersJson = <Map<String, dynamic>>[
  {
    'id': 1,
    'bank_slug': 'standard-chartered',
    'bank_name': 'Standard Chartered',
    'card_types': ['credit'],
    'discount_pct': 15.0,
    'max_discount_amt': 3000.0,
    'min_spend': 5000.0,
    'channel': 'online',
    'valid_from': '2026-06-26',
    'valid_to': '2026-09-24',
    'proof_url': 'https://www.sc.com/pk/promotions/',
  },
  {
    'id': 3,
    'bank_slug': 'meezan',
    'bank_name': 'Meezan Bank',
    'card_types': ['islamic', 'debit'],
    'discount_pct': null,
    'max_discount_amt': null,
    'min_spend': null,
    'channel': 'both',
    'valid_from': null,
    'valid_to': null,
    'proof_url': null,
  },
];

/// Shape mirrors `GET /offers` (see backend/app/api/offers.py) — the same rows
/// plus the brand each one belongs to, null meaning every brand.
const directoryOffersJson = <Map<String, dynamic>>[
  {
    'id': 4,
    'bank_slug': 'bank-alfalah',
    'bank_name': 'Bank Alfalah',
    'brand_slug': 'limelight',
    'brand_name': 'Limelight',
    'card_types': ['credit'],
    'discount_pct': 20.0,
    'max_discount_amt': 5000.0,
    'min_spend': 6000.0,
    'channel': 'both',
    'valid_from': '2026-07-19',
    'valid_to': '2026-08-16',
    'proof_url': 'https://www.bankalfalah.com/',
  },
  {
    'id': 3,
    'bank_slug': 'meezan',
    'bank_name': 'Meezan Bank',
    'brand_slug': null,
    'brand_name': null,
    'card_types': ['islamic', 'debit'],
    'discount_pct': 10.0,
    'max_discount_amt': null,
    'min_spend': null,
    'channel': 'online',
    'valid_from': null,
    'valid_to': null,
    'proof_url': null,
  },
  {
    'id': 1,
    'bank_slug': 'standard-chartered',
    'bank_name': 'Standard Chartered',
    'brand_slug': 'outfitters',
    'brand_name': 'Outfitters',
    'card_types': ['credit'],
    'discount_pct': 15.0,
    'max_discount_amt': 3000.0,
    'min_spend': 5000.0,
    'channel': 'online',
    'valid_from': '2026-06-26',
    'valid_to': '2026-09-24',
    'proof_url': 'https://www.sc.com/pk/promotions/',
  },
];

/// A single offer, built to order. Shared because the chips (US-3) and the
/// directory (US-5) render the same model.
BankOffer offerWith({
  int id = 1,
  String bankSlug = 'ubl',
  String bankName = 'UBL',
  String? brandSlug,
  String? brandName,
  List<String> cardTypes = const ['credit'],
  String channel = 'online',
  double? discountPct = 12,
  double? maxDiscountAmount,
  double? minSpend,
  DateTime? validFrom,
  DateTime? validTo,
  String? proofUrl,
}) => BankOffer(
  id: id,
  bankSlug: bankSlug,
  bankName: bankName,
  brandSlug: brandSlug,
  brandName: brandName,
  cardTypes: cardTypes,
  channel: channel,
  discountPct: discountPct,
  maxDiscountAmount: maxDiscountAmount,
  minSpend: minSpend,
  validFrom: validFrom,
  validTo: validTo,
  proofUrl: proofUrl,
);

/// Shape mirrors `GET /brands` (see backend/app/api/brands.py).
const brandsJson = <Map<String, dynamic>>[
  {
    'id': 4,
    'slug': 'limelight',
    'name': 'Limelight',
    'logo_url': null,
    'categories': ['women'],
    'website_url': 'https://limelight.pk',
    'platform': 'shopify',
  },
  {
    'id': 1,
    'slug': 'outfitters',
    'name': 'Outfitters',
    'logo_url': null,
    'categories': ['women', 'men'],
    'website_url': 'https://outfitters.com.pk',
    'platform': 'shopify',
  },
];
