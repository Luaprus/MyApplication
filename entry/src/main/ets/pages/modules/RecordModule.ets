@Component
export struct RecordModule {
  @BuilderParam quickAskBuilder: () => void;
  @BuilderParam checkInBuilder: () => void;
  @BuilderParam weightPlanBuilder: () => void;
  @BuilderParam calorieBuilder: () => void;
  @BuilderParam recordSectionBuilder: () => void;
  scroller: Scroller = new Scroller();

  @Link waterValue: string;
  @Link waterSubtitle: string;
  @Link waterButtonText: string;
  @Prop stepValue: string = '--';
  @Prop stepSubtitle: string = '';
  @Prop stepButtonText: string = '';

  onWaterClick: () => void = (): void => {};
  onStepClick: () => void = (): void => {};
  onScrollPositionChange: (yOffset: number) => void = (_yOffset: number): void => {};

  build() {
    Scroll(this.scroller) {
      Column({ space: 16 }) {
        this.quickAskBuilder()
        this.checkInBuilder()
        this.weightPlanBuilder()
        this.calorieBuilder()
        this.recordSectionBuilder()

        Row({ space: 12 }) {
          this.statusCard('\u559d\u6c34', this.waterValue, this.waterSubtitle, this.waterButtonText, '#F2FCF9', '#36C79A', () => {
            this.onWaterClick();
          })

          this.statusCard('\u6b65\u6570', this.stepValue, this.stepSubtitle, this.stepButtonText, '#EEF4FF', '#4B8DFF', () => {
            this.onStepClick();
          })
        }
        .width('100%')
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 28 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8FAFC')
    .onDidScroll((_xOffset: number, yOffset: number, _scrollState: ScrollState) => {
      this.onScrollPositionChange(yOffset);
    })
  }

  @Builder
  statusCard(title: string, value: string, subtitle: string, buttonText: string, bgColor: string, tint: string,
    action: () => void) {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        if (title === '\u559d\u6c34') {
          Image($r('app.media.icon_status_water'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
        } else if (title === '\u6b65\u6570') {
          Image($r('app.media.icon_exercise_walk'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
        }

        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')
      }
      .alignItems(VerticalAlign.Center)

      Text(value)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Text(subtitle)
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#607184')

      Button(buttonText)
        .width('100%')
        .height(38)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(tint)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .onClick(() => {
          action();
        })
    }
    .padding(18)
    .layoutWeight(1)
    .backgroundColor(bgColor)
    .borderRadius(24)
    .alignItems(HorizontalAlign.Start)
  }
}
