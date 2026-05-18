import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    // Ensure payment proofs bucket exists
    await _ensureBucket();
  }

  static Future<void> _ensureBucket() async {
    try {
      await client.storage.createBucket(
        SupabaseConfig.proofsBucket,
        BucketOptions(public: false, fileSizeLimit: '10MB'),
      );
    } catch (_) {
      // Bucket already exists — OK
    }
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final res = await client
        .from('users')
        .select()
        .eq('email', email.toLowerCase().trim())
        .maybeSingle();
    return res;
  }

  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String fullName,
    String? phone,
    String? xtreamUser,
  }) async {
    final existing = await getUserByEmail(email);
    if (existing != null) return existing;

    final res = await client.from('users').insert({
      'email': email.toLowerCase().trim(),
      'full_name': fullName.trim(),
      'phone': phone?.trim(),
      'xtream_user': xtreamUser?.trim(),
      'role': 'pending',
    }).select().single();
    return res;
  }

  static Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await client.from('users').update(data).eq('id', userId);
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getActiveSubscription(String userId) async {
    final res = await client
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .inFilter('status', ['active', 'trial'])
        .order('end_date', ascending: false)
        .limit(1)
        .maybeSingle();
    return res;
  }

  static Future<List<Map<String, dynamic>>> getUserSubscriptions(
      String userId) async {
    final res = await client
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> submitPayment({
    required String userId,
    required double amount,
    required String currency,
    required String method,
    String? reference,
    String? notes,
    File? proofFile,
    Uint8List? proofBytes,
    String? proofFilename,
  }) async {
    String? proofUrl;
    String? storedFilename;

    // Upload proof to Supabase Storage
    if (proofFile != null || proofBytes != null) {
      storedFilename = '${userId}_${DateTime.now().millisecondsSinceEpoch}_'
          '${proofFilename ?? 'comprobante.jpg'}';

      if (proofFile != null) {
        await client.storage
            .from(SupabaseConfig.proofsBucket)
            .upload(storedFilename, proofFile);
      } else if (proofBytes != null) {
        await client.storage
            .from(SupabaseConfig.proofsBucket)
            .uploadBinary(storedFilename, proofBytes);
      }

      proofUrl = client.storage
          .from(SupabaseConfig.proofsBucket)
          .getPublicUrl(storedFilename);
    }

    final payment = await client.from('payments').insert({
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'method': method,
      'status': 'pending_review',
      'proof_url': proofUrl,
      'proof_filename': storedFilename ?? proofFilename,
      'reference': reference?.trim(),
      'notes': notes?.trim(),
    }).select().single();

    return payment;
  }

  static Future<List<Map<String, dynamic>>> getUserPayments(
      String userId) async {
    final res = await client
        .from('payments')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // ── Suggestions ───────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getSuggestions({
    String? type,
    bool onlyAdded = false,
  }) async {
    var query = client.from('suggestions').select();
    if (type != null) query = query.eq('type', type);
    if (onlyAdded) query = query.eq('is_added', true);
    final res = await query.order('votes', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<Map<String, dynamic>> submitSuggestion({
    required String userId,
    required String title,
    required String type,
    int? year,
    String? description,
  }) async {
    final res = await client.from('suggestions').insert({
      'user_id': userId,
      'title': title.trim(),
      'type': type,
      'year': year,
      'description': description?.trim(),
      'votes': 1,
    }).select().single();
    return res;
  }

  static Future<void> voteSuggestion(
      String suggestionId, String userId) async {
    try {
      await client
          .from('suggestion_votes')
          .insert({'suggestion_id': suggestionId, 'user_id': userId});
      // Increment vote counter
      await client.rpc('increment_suggestion_votes',
          params: {'suggestion_id': suggestionId});
    } catch (_) {
      // Already voted — ignore
    }
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final res = await client
        .from('users')
        .select('*, subscriptions(status, end_date, plan_name)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<List<Map<String, dynamic>>> getPendingPayments() async {
    final res = await client
        .from('pending_payments')
        .select();
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> approvePayment({
    required String paymentId,
    required String userId,
    required String reviewerId,
    required double amount,
    required String currency,
    required String planName,
    required int durationDays,
  }) async {
    // 1. Mark payment as approved
    await client.from('payments').update({
      'status': 'approved',
      'reviewed_by': reviewerId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);

    // 2. Expire old active subscriptions
    await client
        .from('subscriptions')
        .update({'status': 'expired'})
        .eq('user_id', userId)
        .inFilter('status', ['active', 'trial', 'pending']);

    // 3. Create new subscription
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: durationDays));
    await client.from('subscriptions').insert({
      'user_id': userId,
      'plan_name': planName,
      'plan_price': amount,
      'currency': currency,
      'status': 'active',
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
    });

    // 4. Activate user
    await client
        .from('users')
        .update({'role': 'subscriber', 'is_active': true})
        .eq('id', userId);
  }

  static Future<void> rejectPayment({
    required String paymentId,
    required String reviewerId,
    String? adminNotes,
  }) async {
    await client.from('payments').update({
      'status': 'rejected',
      'reviewed_by': reviewerId,
      'reviewed_at': DateTime.now().toIso8601String(),
      'admin_notes': adminNotes,
    }).eq('id', paymentId);
  }
}
