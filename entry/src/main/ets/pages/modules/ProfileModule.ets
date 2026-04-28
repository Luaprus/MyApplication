@Component
export struct ProfileModule {
  @BuilderParam heroBuilder: () => void;
  @BuilderParam statsBuilder: () => void;
  @BuilderParam tagsBuilder: () => void;
  @BuilderParam menuBuilder: () => void;
  @BuilderParam logoutBuilder: () => void;
  @BuilderParam footerBuilder: () => void;

  build() {
    Scroll() {
      Column({ space: 18 }) {
        this.heroBuilder()
        this.statsBuilder()
        this.tagsBuilder()
        this.menuBuilder()
        this.logoutBuilder()
        this.footerBuilder()
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 28 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8FAFC')
  }
}
