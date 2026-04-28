import { ChatMessage } from '../../models/AppState';
import { SuggestionItem } from '../../models/PageModels';

@Component
export struct AiModule {
  @Link chatInput: string;
  @Prop isRequesting: boolean = false;
  @Prop messages: ChatMessage[] = [];
  @Prop suggestions: SuggestionItem[] = [];

  onSuggestionSelect: (label: string) => void = (_label: string): void => {};
  onSend: () => void = (): void => {};
  onClearHistory: () => void = (): void => {};

  safeChatInput(): string {
    return this.chatInput ? this.chatInput : '';
  }

  canSendChat(): boolean {
    return this.safeChatInput().trim().length > 0 && !this.isRequesting;
  }

  build() {
    Column() {
      this.aiHeader()

      List({ space: 14 }) {
        ForEach(this.messages, (message: ChatMessage) => {
          ListItem() {
            this.messageBubble(message)
          }
        }, (message: ChatMessage) => message.id.toString())
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor('#F8FAFC')
      .alignListItem(ListItemAlign.Start)
      .edgeEffect(EdgeEffect.Spring)

      this.suggestionBar()
      this.chatInputBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8FAFC')
  }

  @Builder
  aiHeader() {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Row() {
          Image($r('app.media.icon_ai_spark'))
            .width(30)
            .height(30)
            .objectFit(ImageFit.Contain)
        }
        .width(48)
        .height(48)
        .borderRadius(16)
        .backgroundColor('#ECFBF5')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Row()
          .width(14)
          .height(14)
          .borderRadius(7)
          .backgroundColor('#22C55E')
          .borderWidth(2)
          .borderColor('#FFFFFF')
      }

      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text('AI \u5065\u5eb7\u52a9\u624b')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')

          Text('\u5728\u7ebf')
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#36C79A')
            .borderRadius(10)
        }

        Text(this.isRequesting ? '\u6b63\u5728\u601d\u8003\u4e2d...' : '\u4f1a\u7ed3\u5408\u996e\u98df\u3001\u4f53\u91cd\u548c\u8fd0\u52a8\u8bb0\u5f55\u7ed9\u4f60\u5efa\u8bae')
          .fontSize(12)
          .fontColor(this.isRequesting ? '#36C79A' : '#94A3B8')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.messages.length > 1) {
        Button('\u6e05\u7a7a')
          .height(34)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#607184')
          .backgroundColor('#F8FAFC')
          .borderRadius(14)
          .padding({ left: 10, right: 10 })
          .onClick(() => {
            this.onClearHistory();
          })
      } else {
        Text('\u5386\u53f2')
          .fontSize(13)
          .fontColor('#607184')
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .backgroundColor('#F8FAFC')
          .borderRadius(14)
      }
    }
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .width('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  messageBubble(message: ChatMessage) {
    Row({ space: 8 }) {
      if (message.role === 'assistant') {
        Row() {
          Image($r('app.media.icon_ai_spark'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
        }
        .width(34)
        .height(34)
        .borderRadius(12)
        .backgroundColor('#ECFBF5')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ top: 4 })
      }

      Column() {
        if (message.isThinking === true) {
          Row({ space: 10 }) {
            LoadingProgress()
              .width(18)
              .height(18)
              .color('#36C79A')

            Text(message.content)
              .fontSize(15)
              .lineHeight(24)
              .fontColor('#334155')
          }
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor('#FFFFFF')
          .borderRadius({ topLeft: 8, topRight: 18, bottomLeft: 18, bottomRight: 18 })
        } else {
          Text(message.content)
            .fontSize(15)
            .lineHeight(24)
            .fontColor(message.role === 'assistant' ? '#334155' : '#FFFFFF')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .backgroundColor(message.role === 'assistant' ? '#FFFFFF' : '#36C79A')
            .borderRadius(message.role === 'assistant'
              ? { topLeft: 8, topRight: 18, bottomLeft: 18, bottomRight: 18 }
              : { topLeft: 18, topRight: 8, bottomLeft: 18, bottomRight: 18 })
        }
      }
      .width('76%')
      .alignItems(message.role === 'assistant' ? HorizontalAlign.Start : HorizontalAlign.End)

      if (message.role === 'user') {
        Row() {
          Text('\u6211')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .width(34)
        .height(34)
        .borderRadius(12)
        .backgroundColor('#36C79A')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ top: 4 })
      }
    }
    .width('100%')
    .justifyContent(message.role === 'assistant' ? FlexAlign.Start : FlexAlign.End)
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  suggestionBar() {
    Column({ space: 8 }) {
      Row() {
        Text('\u5feb\u6377\u63d0\u95ee')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#94A3B8')
      }
      .width('100%')

      Row({ space: 8 }) {
        ForEach(this.suggestions, (item: SuggestionItem) => {
          Button(item.label)
            .layoutWeight(1)
            .height(40)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(item.tint)
            .backgroundColor(item.bgColor)
            .borderRadius(14)
            .onClick(() => {
              this.onSuggestionSelect(item.label);
            })
        }, (item: SuggestionItem) => item.id.toString())
      }
      .width('100%')
    }
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .width('100%')
    .backgroundColor('#F8FAFC')
  }

  @Builder
  chatInputBar() {
    Row({ space: 10 }) {
      TextInput({ text: this.safeChatInput(), placeholder: '\u8f93\u5165\u4f60\u7684\u95ee\u9898...' })
        .layoutWeight(1)
        .height(46)
        .fontSize(15)
        .fontColor('#1F2937')
        .backgroundColor('#F8FAFC')
        .borderRadius(16)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.chatInput = value;
        })

      Button() {
        Image($r('app.media.icon_send_arrow'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
      }
      .width(46)
      .height(46)
      .backgroundColor(this.canSendChat() ? '#36C79A' : '#B7C2D1')
      .borderRadius(16)
      .opacity(this.canSendChat() ? 1 : 0.72)
      .onClick(() => {
        if (this.canSendChat()) {
          this.onSend();
        }
      })
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 18 })
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
