import { router } from '@kit.ArkUI';
import { AppConstants } from '../constants/AppConstants';
import { QuoteConstants } from '../constants/QuoteConstants';

@Entry
@Component
struct SplashPage {
  @State quote: string = '';
  @State opacityValue: number = 0;

  aboutToAppear(): void {
    this.quote = QuoteConstants.getRandomQuote();
    setTimeout(() => {
      animateTo({ duration: 800, curve: Curve.EaseOut }, () => { this.opacityValue = 1; });
    }, 100);
    setTimeout(() => { router.replaceUrl({ url: 'pages/HomePage' }); }, 2000);
  }

  build() {
    Column() {
      Column().layoutWeight(1);
      Column() {
        Text('🧭').fontSize(80).margin({ bottom: 24 })
        Text(AppConstants.APP_NAME).fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1A1A2E').letterSpacing(4)
      }
      .opacity(this.opacityValue)
      Text(this.quote).fontSize(16).fontColor('#666666').textAlign(TextAlign.Center).maxLines(2)
        .padding({ left: 48, right: 48 }).margin({ top: 48 }).opacity(this.opacityValue)
      Column().layoutWeight(1);
      Text('v1.0.0 · 随心漫步').fontSize(12).fontColor('#AAAAAA').margin({ bottom: 48 }).opacity(this.opacityValue)
    }
    .width('100%').height('100%').backgroundColor('#F8F9FA')
  }
}
