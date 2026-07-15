package com.fhsocial.backend.Entities;

import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MapsId;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "user_settings")
public class UserSettingsEntity {

    @Id
    private UUID id;
    
    @MapsId
    @OneToOne
    @JoinColumn(name = "user_settings_user_id")
    private UserEntity user;

    @Column(nullable = false)
    private String themeColor = "orange";

    @Column(nullable = false)
    private String brightness = "system";

    @Column(nullable = false)
    private boolean iconButtons = true;

    UserSettingsEntity() {}

    public UserSettingsEntity(UserEntity user) {
        this.user = user;
        user.setUserSettings(this);
    }

    public UserEntity getUser() {
        return user;
    }

    public void setUser(UserEntity user) {
        this.user = user;
        this.id = user.getId();
    }

    public String getThemeColor() {
        return themeColor;
    }

    public void setThemeColor(String themeColor) {
        this.themeColor = themeColor;
    }

    public String getBrightness() {
        return brightness;
    }

    public void setBrightness(String themeBrightness) {
        this.brightness = themeBrightness;
    }

    public boolean isIconButtons() {
        return iconButtons;
    }

    public void setIconButtons(boolean iconButtons) {
        this.iconButtons = iconButtons;
    }
}
