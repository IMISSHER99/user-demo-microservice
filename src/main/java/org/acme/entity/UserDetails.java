package org.acme.entity;

import io.quarkus.hibernate.reactive.panache.PanacheEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;

@Entity
public class UserDetails extends PanacheEntity {

    @Column(length = 40, unique = true, nullable = false)
    private String username;
    @Column(length = 50, unique = true, nullable = false)
    private String email;
    @Column(unique = true, nullable = false)
    private String password;
    @Column(columnDefinition = "BOOLEAN DEFAULT TRUE")
    private boolean isEnabled = true;
    @Column(columnDefinition = "BOOLEAN DEFAULT FALSE")
    private boolean isPasswordExpired = false;

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public boolean isEnabled() {
        return isEnabled;
    }

    public void setEnabled(boolean enabled) {
        isEnabled = enabled;
    }

    public boolean isPasswordExpired() {
        return isPasswordExpired;
    }

    public void setPasswordExpired(boolean passwordExpired) {
        isPasswordExpired = passwordExpired;
    }
}
