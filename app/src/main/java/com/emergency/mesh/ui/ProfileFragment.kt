package com.emergency.mesh.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.fragment.app.Fragment
import com.emergency.mesh.MainActivity
import com.emergency.mesh.R
import com.emergency.mesh.models.UserProfile
import com.emergency.mesh.models.UserRole
import com.google.android.material.button.MaterialButton

/**
 * Profile screen fragment with user info and settings
 */
class ProfileFragment : Fragment() {

    private lateinit var mainActivity: MainActivity
    
    // Views
    private lateinit var tvUserName: TextView
    private lateinit var tvUserRole: TextView
    private lateinit var etName: EditText
    private lateinit var etPhone: EditText
    private lateinit var etEmergencyContact: EditText
    private lateinit var etBloodType: EditText
    private lateinit var etMedicalInfo: EditText
    private lateinit var btnSaveProfile: MaterialButton
    private lateinit var languageSelector: LinearLayout
    private lateinit var tvCurrentLanguage: TextView
    private lateinit var roleSelector: LinearLayout
    private lateinit var tvCurrentRole: TextView

    companion object {
        private val LANGUAGES = listOf(
            "en" to R.string.lang_english,
            "hi" to R.string.lang_hindi,
            "ta" to R.string.lang_tamil,
            "te" to R.string.lang_telugu,
            "bn" to R.string.lang_bengali
        )
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_profile, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        mainActivity = requireActivity() as MainActivity
        
        initViews(view)
        loadUserData()
        setupListeners()
    }

    private fun initViews(view: View) {
        tvUserName = view.findViewById(R.id.tvUserName)
        tvUserRole = view.findViewById(R.id.tvUserRole)
        etName = view.findViewById(R.id.etName)
        etPhone = view.findViewById(R.id.etPhone)
        etEmergencyContact = view.findViewById(R.id.etEmergencyContact)
        etBloodType = view.findViewById(R.id.etBloodType)
        etMedicalInfo = view.findViewById(R.id.etMedicalInfo)
        btnSaveProfile = view.findViewById(R.id.btnSaveProfile)
        languageSelector = view.findViewById(R.id.languageSelector)
        tvCurrentLanguage = view.findViewById(R.id.tvCurrentLanguage)
        roleSelector = view.findViewById(R.id.roleSelector)
        tvCurrentRole = view.findViewById(R.id.tvCurrentRole)
    }

    private fun loadUserData() {
        // Load user profile
        val profile = mainActivity.userProfile
        if (profile != null) {
            tvUserName.text = profile.name
            etName.setText(profile.name)
            etPhone.setText(profile.phone)
            etEmergencyContact.setText(profile.emergencyContact)
            etBloodType.setText(profile.bloodType)
            etMedicalInfo.setText(profile.medicalInfo)
        }
        
        // Load role
        updateRoleDisplay()
        
        // Load language
        updateLanguageDisplay()
    }

    private fun setupListeners() {
        btnSaveProfile.setOnClickListener {
            saveProfile()
        }
        
        languageSelector.setOnClickListener {
            showLanguageDialog()
        }
        
        roleSelector.setOnClickListener {
            showRoleDialog()
        }
    }

    private fun saveProfile() {
        val name = etName.text.toString().trim()
        
        if (name.isBlank()) {
            Toast.makeText(context, R.string.name_required, Toast.LENGTH_SHORT).show()
            return
        }
        
        val profile = UserProfile(
            name = name,
            phone = etPhone.text.toString().trim(),
            emergencyContact = etEmergencyContact.text.toString().trim(),
            bloodType = etBloodType.text.toString().trim(),
            medicalInfo = etMedicalInfo.text.toString().trim()
        )
        
        UserProfile.save(requireContext(), profile)
        
        // Update display
        tvUserName.text = profile.name
        
        Toast.makeText(context, R.string.profile_saved, Toast.LENGTH_SHORT).show()
    }

    private fun showLanguageDialog() {
        val languageNames = LANGUAGES.map { getString(it.second) }.toTypedArray()
        val currentLanguage = mainActivity.getCurrentLanguage()
        val currentIndex = LANGUAGES.indexOfFirst { it.first == currentLanguage }.coerceAtLeast(0)
        
        AlertDialog.Builder(requireContext())
            .setTitle(R.string.select_language)
            .setSingleChoiceItems(languageNames, currentIndex) { dialog, which ->
                val selectedLanguage = LANGUAGES[which].first
                dialog.dismiss()
                mainActivity.setLanguage(selectedLanguage)
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun showRoleDialog() {
        val roles = arrayOf(getString(R.string.role_citizen), getString(R.string.role_official))
        val currentIndex = if (mainActivity.userRole == UserRole.CITIZEN) 0 else 1
        
        AlertDialog.Builder(requireContext())
            .setTitle(R.string.select_role)
            .setSingleChoiceItems(roles, currentIndex) { dialog, which ->
                val selectedRole = if (which == 0) UserRole.CITIZEN else UserRole.OFFICIAL
                dialog.dismiss()
                mainActivity.updateUserRole(selectedRole)
                updateRoleDisplay()
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun updateRoleDisplay() {
        val roleText = if (mainActivity.userRole == UserRole.CITIZEN) {
            getString(R.string.role_citizen)
        } else {
            getString(R.string.role_official)
        }
        tvUserRole.text = roleText
        tvCurrentRole.text = roleText
    }

    private fun updateLanguageDisplay() {
        val currentLanguage = mainActivity.getCurrentLanguage()
        val languageEntry = LANGUAGES.find { it.first == currentLanguage } ?: LANGUAGES[0]
        tvCurrentLanguage.text = getString(languageEntry.second)
    }
}
