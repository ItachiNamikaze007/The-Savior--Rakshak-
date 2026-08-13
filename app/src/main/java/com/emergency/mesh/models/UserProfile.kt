package com.emergency.mesh.models

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import java.io.Serializable

/**
 * User profile containing basic information sent with SOS messages
 */
data class UserProfile(
    val name: String,
    val phone: String = "",
    val emergencyContact: String = "",
    val bloodType: String = "",
    val medicalInfo: String = ""
) : Serializable {

    /**
     * Check if profile has required fields filled
     */
    fun isValid(): Boolean {
        return name.isNotBlank()
    }

    /**
     * Get formatted profile string for SOS messages
     */
    fun getSOSInfo(): String {
        val sb = StringBuilder()
        sb.append("Name: $name")
        if (phone.isNotBlank()) sb.append("\nPhone: $phone")
        if (emergencyContact.isNotBlank()) sb.append("\nEmergency Contact: $emergencyContact")
        if (bloodType.isNotBlank()) sb.append("\nBlood Type: $bloodType")
        if (medicalInfo.isNotBlank()) sb.append("\nMedical Info: $medicalInfo")
        return sb.toString()
    }

    companion object {
        private const val PREF_NAME = "user_profile"
        private const val KEY_PROFILE = "profile_json"

        /**
         * Save profile to SharedPreferences
         */
        fun save(context: Context, profile: UserProfile) {
            val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            val json = Gson().toJson(profile)
            prefs.edit().putString(KEY_PROFILE, json).apply()
        }

        /**
         * Load profile from SharedPreferences
         */
        fun load(context: Context): UserProfile? {
            val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(KEY_PROFILE, null) ?: return null
            return try {
                Gson().fromJson(json, UserProfile::class.java)
            } catch (e: Exception) {
                null
            }
        }

        /**
         * Check if profile exists
         */
        fun exists(context: Context): Boolean {
            return load(context)?.isValid() == true
        }

        /**
         * Clear profile
         */
        fun clear(context: Context) {
            val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            prefs.edit().remove(KEY_PROFILE).apply()
        }
    }
}
