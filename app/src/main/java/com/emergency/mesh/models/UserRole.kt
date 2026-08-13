package com.emergency.mesh.models

/**
 * User role in the emergency mesh system
 */
enum class UserRole {
    CITIZEN,    // Can send SOS, view messages
    OFFICIAL    // Can view SOS map and respond
}
