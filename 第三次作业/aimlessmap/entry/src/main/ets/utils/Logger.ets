export class Logger {
  private static readonly TAG: string = 'AimlessMap';
  static info(msg: string): void { console.info(`${Logger.TAG}: ${msg}`); }
  static error(msg: string): void { console.error(`${Logger.TAG}: ${msg}`); }
  static warn(msg: string): void { console.warn(`${Logger.TAG}: ${msg}`); }
}
