import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_providers.g.dart';

@riverpod
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;

@riverpod
Stream<AuthState> authStateChanges(Ref ref) =>
    ref.watch(supabaseClientProvider).auth.onAuthStateChange;
