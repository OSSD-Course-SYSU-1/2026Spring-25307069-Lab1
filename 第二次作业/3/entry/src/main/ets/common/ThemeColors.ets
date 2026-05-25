/*
 * Theme Colors
 * Provides light/dark theme color palette
 */

export class ThemeColors {
  // Theme state
  readonly isDark: boolean;

  // Background colors
  readonly pageBackground: string;
  readonly cardBackground: string;
  readonly controlBarBackground: string;
  readonly inputBackground: string;
  readonly buttonBackground: string;

  // Text colors
  readonly primaryText: string;
  readonly secondaryText: string;
  readonly disabledText: string;

  // Border colors
  readonly borderColor: string;
  readonly dividerColor: string;

  // Accent color (stays the same in both themes)
  readonly accentColor: string = '#F67609';

  // Video player internal (always dark)
  readonly playerBackground: string = '#000000';
  readonly playerControlBg: string = '#CC000000';
  readonly playerButtonBg: string = '#333333';
  readonly playerSliderTrack: string = '#464642';
  readonly playerVideoItemBg: string = '#3B3A37';
  readonly playerDisabledText: string = '#555555';

  constructor(isDark: boolean) {
    this.isDark = isDark;
    if (isDark) {
      this.pageBackground = '#000000';
      this.cardBackground = '#1A1A1A';
      this.controlBarBackground = '#1A1A1A';
      this.inputBackground = '#2A2A2A';
      this.buttonBackground = '#333333';
      this.primaryText = '#FFFFFF';
      this.secondaryText = '#A6A6A6';
      this.disabledText = '#555555';
      this.borderColor = '#444444';
      this.dividerColor = '#444444';
    } else {
      this.pageBackground = '#F5F5F5';
      this.cardBackground = '#FFFFFF';
      this.controlBarBackground = '#FFFFFF';
      this.inputBackground = '#F0F0F0';
      this.buttonBackground = '#E8E8E8';
      this.primaryText = '#1A1A1A';
      this.secondaryText = '#666666';
      this.disabledText = '#AAAAAA';
      this.borderColor = '#DDDDDD';
      this.dividerColor = '#EEEEEE';
    }
  }
}
