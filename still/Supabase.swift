//======================================================================
// MARK: - Supabase.swift
// Purpose: Supabase implementation (Supabaseの実装)
// Path: still/Supabase.swift
//======================================================================

import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: Config.supabaseURL)!,
    supabaseKey: Config.supabaseAnonKey
)