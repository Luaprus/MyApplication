import { AuthMode } from '../../models/AppState';
import { decimalText, integerText } from '../../models/InputValidation';

@Component
export struct AuthModule {
  @Link authMode: AuthMode;
  @Link loginEmail: string;
  @Link loginPassword: string;
  @Link registerName: string;
  @Link registerEmail: string;
  @Link registerPassword: string;
  @Link registerConfirmPassword: string;
  @Link authError: string;

  @Prop isAuthSubmitting: boolean = false;
  @Prop authHint: string = '';

  onSwitchAuthMode: (mode: AuthMode) => void = (_mode: AuthMode): void => {};
  onUseDemoAccount: () => void = (): void => {};
  onSubmitLogin: () => void = (): void => {};
  onSubmitRegister: () => void = (): void => {};

  safeText(value: string): string {
    return value ? value : '';
  }

  build() {
    Scroll() {
      Column({ space: 22 }) {
        this.authHero()
        this.modeSwitch()

        Column({ space: 14 }) {
          if (this.authMode === 'register') {
            this.authInputCard('\u6635\u79f0', '\u4f8b\u5982\uff1a\u5c0f\u660e', this.registerName, false, (value: string) => {
              this.registerName = value;
              this.authError = '';
            })
          }

          this.authInputCard('\u90ae\u7bb1', '\u8f93\u5165\u90ae\u7bb1\u8d26\u53f7',
            this.authMode === 'login' ? this.loginEmail : this.registerEmail, false, (value: string) => {
              if (this.authMode === 'login') {
                this.loginEmail = value;
              } else {
                this.registerEmail = value;
              }
              this.authError = '';
            })

          this.authInputCard('\u5bc6\u7801', '\u8f93\u5165\u5bc6\u7801',
            this.authMode === 'login' ? this.loginPassword : this.registerPassword, true, (value: string) => {
              if (this.authMode === 'login') {
                this.loginPassword = value;
              } else {
                this.registerPassword = value;
              }
              this.authError = '';
            })

          if (this.authMode === 'register') {
            this.authInputCard('\u786e\u8ba4\u5bc6\u7801', '\u518d\u8f93\u5165\u4e00\u6b21\u5bc6\u7801', this.registerConfirmPassword, true, (value: string) => {
              this.registerConfirmPassword = value;
              this.authError = '';
            })
          }

          if (this.authError.length > 0) {
            Text(this.authError)
              .fontSize(12)
              .lineHeight(18)
              .fontColor('#EF4444')
              .width('100%')
          }

          Button(this.isAuthSubmitting
            ? '\u5904\u7406\u4e2d...'
            : (this.authMode === 'login' ? '\u7acb\u5373\u767b\u5f55' : '\u5b8c\u6210\u6ce8\u518c'))
            .width('100%')
            .height(54)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor('#36C79A')
            .borderRadius(18)
            .onClick(() => {
              if (this.authMode === 'login') {
                this.onSubmitLogin();
              } else {
                this.onSubmitRegister();
              }
            })
        }
        .width('100%')

        Column({ space: 12 }) {
          Text('\u5feb\u901f\u8fdb\u5165')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#94A3B8')

          Row({ space: 10 }) {
            this.authActionButton('\u6f14\u793a\u8d26\u53f7', '#36C79A', '#ECFBF5', () => {
              this.onUseDemoAccount();
            })
            this.authActionButton(this.authMode === 'login' ? '\u53bb\u6ce8\u518c' : '\u8fd4\u56de\u767b\u5f55', '#4B8DFF', '#EEF4FF', () => {
              this.onSwitchAuthMode(this.authMode === 'login' ? 'register' : 'login');
            })
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        if (this.authHint.length > 0) {
          Text(this.authHint)
            .fontSize(12)
            .lineHeight(18)
            .fontColor('#94A3B8')
            .width('100%')
        }

        Row({ space: 8 }) {
          Text(this.authMode === 'login' ? '\u8fd8\u6ca1\u6709\u8d26\u53f7\uff1f' : '\u5df2\u6709\u8d26\u53f7\uff1f')
            .fontSize(14)
            .fontColor('#94A3B8')

          Text(this.authMode === 'login' ? '\u7acb\u5373\u6ce8\u518c' : '\u53bb\u767b\u5f55')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#36C79A')
            .onClick(() => {
              this.onSwitchAuthMode(this.authMode === 'login' ? 'register' : 'login');
            })
        }
      }
      .padding({ left: 24, right: 24, top: 58, bottom: 48 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  authHero() {
    Column({ space: 12 }) {
      Row() {
        Row() {
          Image($r('app.media.icon_ai_spark'))
            .width(34)
            .height(34)
            .objectFit(ImageFit.Contain)
        }
        .width(54)
        .height(54)
        .borderRadius(18)
        .backgroundColor('#ECFBF5')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')

      Text(this.authMode === 'login' ? '\u5f00\u542f\u4f60\u7684\u5065\u5eb7\u65c5\u7a0b' : '\u6ce8\u518c\u4f60\u7684\u5065\u5eb7\u8d26\u53f7')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Text(this.authMode === 'login'
        ? '\u767b\u5f55\u540e\u540c\u6b65\u8fd0\u52a8\u3001\u4f53\u91cd\u548c\u996e\u98df\u8bb0\u5f55'
        : '\u521b\u5efa\u4e00\u4e2a\u53ef\u7528\u8d26\u53f7\uff0c\u7ee7\u7eed\u8bb0\u5f55\u4e0e AI \u5065\u5eb7\u5efa\u8bae')
        .fontSize(14)
        .lineHeight(22)
        .fontColor('#94A3B8')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  modeSwitch() {
    Row({ space: 8 }) {
      this.modeButton('\u767b\u5f55', this.authMode === 'login', () => {
        this.onSwitchAuthMode('login');
      })
      this.modeButton('\u6ce8\u518c', this.authMode === 'register', () => {
        this.onSwitchAuthMode('register');
      })
    }
    .width('100%')
    .padding(6)
    .backgroundColor('#F8FAFC')
    .borderRadius(18)
  }

  @Builder
  modeButton(title: string, active: boolean, action: () => void) {
    Button(title)
      .layoutWeight(1)
      .height(42)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(active ? '#0F172A' : '#94A3B8')
      .backgroundColor(active ? '#FFFFFF' : '#F8FAFC')
      .borderRadius(14)
      .padding(0)
      .onClick(() => {
        action();
      })
  }

  @Builder
  authInputCard(title: string, placeholder: string, value: string, isPassword: boolean, onChange: (value: string) => void) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#607184')

      TextInput({ text: this.safeText(value), placeholder: placeholder })
        .width('100%')
        .height(52)
        .fontSize(15)
        .fontColor('#0F172A')
        .backgroundColor('#F8FAFC')
        .borderRadius(16)
        .padding({ left: 16, right: 16 })
        .type(isPassword ? InputType.Password : InputType.Normal)
        .onChange((nextValue: string) => {
          onChange(nextValue);
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  authActionButton(title: string, tint: string, bgColor: string, action: () => void) {
    Button(title)
      .layoutWeight(1)
      .height(42)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(tint)
      .backgroundColor(bgColor)
      .borderRadius(14)
      .padding(0)
      .onClick(() => {
        action();
      })
  }
}

@Component
export struct OnboardingModule {
  @Link onboardingName: string;
  @Link onboardingGender: string;
  @Link onboardingAge: string;
  @Link onboardingHeight: string;
  @Link onboardingCurrentWeight: string;
  @Link onboardingTargetWeight: string;
  @Link onboardingWeeklyTarget: string;
  @Link onboardingError: string;

  @Prop isOnboardingSubmitting: boolean = false;
  onSubmit: () => void = (): void => {};

  safeText(value: string): string {
    return value ? value : '';
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        this.onboardingHero()

        this.onboardingInputCard('\u6635\u79f0', '\u4f8b\u5982\uff1a\u5c0f\u660e', this.onboardingName, InputType.Normal, (value: string) => {
          this.onboardingName = value;
          this.onboardingError = '';
        })

        Column({ space: 10 }) {
          Text('\u6027\u522b')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#607184')

          Row({ space: 10 }) {
            this.choiceButton('\u7537', this.onboardingGender === '\u7537')
            this.choiceButton('\u5973', this.onboardingGender === '\u5973')
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Row({ space: 10 }) {
          this.onboardingInputCard('\u5e74\u9f84', '\u4f8b\u5982\uff1a24', this.onboardingAge, InputType.Number, (value: string) => {
            this.onboardingAge = integerText(value);
            this.onboardingError = '';
          })
          this.onboardingInputCard('\u8eab\u9ad8(cm)', '\u4f8b\u5982\uff1a168.5', this.onboardingHeight, InputType.Normal, (value: string) => {
            this.onboardingHeight = decimalText(value);
            this.onboardingError = '';
          })
        }
        .width('100%')

        this.onboardingInputCard('\u5f53\u524d\u4f53\u91cd(kg)', '\u4f8b\u5982\uff1a62.5', this.onboardingCurrentWeight, InputType.Normal, (value: string) => {
          this.onboardingCurrentWeight = decimalText(value);
          this.onboardingError = '';
        })
        this.onboardingInputCard('\u76ee\u6807\u4f53\u91cd(kg)', '\u4f8b\u5982\uff1a57.0', this.onboardingTargetWeight, InputType.Normal, (value: string) => {
          this.onboardingTargetWeight = decimalText(value);
          this.onboardingError = '';
        })
        this.onboardingInputCard('\u6bcf\u5468\u76ee\u6807(kg)', '\u4f8b\u5982\uff1a0.3', this.onboardingWeeklyTarget, InputType.Normal, (value: string) => {
          this.onboardingWeeklyTarget = decimalText(value);
          this.onboardingError = '';
        })

        if (this.onboardingError.length > 0) {
          Text(this.onboardingError)
            .fontSize(12)
            .lineHeight(18)
            .fontColor('#EF4444')
            .width('100%')
        }

        Button(this.isOnboardingSubmitting ? '\u4fdd\u5b58\u4e2d...' : '\u5f00\u59cb\u4f7f\u7528')
          .width('100%')
          .height(54)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#36C79A')
          .borderRadius(18)
          .onClick(() => {
            this.onSubmit();
          })
      }
      .padding({ left: 24, right: 24, top: 50, bottom: 40 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  onboardingHero() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Row() {
          Image($r('app.media.icon_profile_goal'))
            .width(34)
            .height(34)
            .objectFit(ImageFit.Contain)
        }
        .width(54)
        .height(54)
        .borderRadius(18)
        .backgroundColor('#FFF7EE')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Column({ space: 4 }) {
          Text('\u57fa\u7840\u4fe1\u606f')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#36C79A')

          Text('1 / 1')
            .fontSize(12)
            .fontColor('#94A3B8')
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Text('\u5148\u5b8c\u6210\u4f60\u7684\u57fa\u7840\u4fe1\u606f')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Text('\u6211\u4eec\u4f1a\u7528\u8fd9\u4e9b\u6570\u636e\u521d\u59cb\u5316\u4f53\u91cd\u3001\u76ee\u6807\u548c\u8bb0\u5f55\u9875\u72b6\u6001')
        .fontSize(14)
        .lineHeight(22)
        .fontColor('#94A3B8')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  onboardingInputCard(title: string, placeholder: string, value: string, inputType: InputType, onChange: (value: string) => void) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#607184')

      TextInput({ text: this.safeText(value), placeholder: placeholder })
        .width('100%')
        .height(52)
        .fontSize(15)
        .fontColor('#0F172A')
        .backgroundColor('#F8FAFC')
        .borderRadius(16)
        .padding({ left: 16, right: 16 })
        .type(inputType)
        .onChange((nextValue: string) => {
          onChange(nextValue);
        })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  choiceButton(title: string, active: boolean) {
    Button(active ? title + '  已选' : title)
      .layoutWeight(1)
      .height(46)
      .fontSize(15)
      .fontWeight(FontWeight.Bold)
      .fontColor(active ? '#FFFFFF' : '#607184')
      .backgroundColor(active ? '#36C79A' : '#F8FAFC')
      .borderRadius(14)
      .padding(0)
      .onClick(() => {
        this.onboardingGender = title;
        this.onboardingError = '';
      })
  }
}
