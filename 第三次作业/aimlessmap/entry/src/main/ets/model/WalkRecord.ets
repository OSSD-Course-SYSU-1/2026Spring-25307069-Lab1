export interface TrailPoint {
  latitude: number;
  longitude: number;
  direction: string;
  index: number;
}

export class WalkRecord {
  id: string = '';
  date: string = '';
  duration: number = 0;
  direction: string = '';
  redirectCount: number = 0;
  feeling: string = '';      // 用户感受
  photos: string[] = [];     // 照片路径数组
  trail: TrailPoint[] = [];  // 漫步轨迹

  constructor(duration: number, direction: string, redirectCount: number, feeling: string = '', photos: string[] = [], trail: TrailPoint[] = []) {
    this.id = `walk_${Date.now()}`;
    const d = new Date();
    this.date = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
    this.duration = duration;
    this.direction = direction;
    this.redirectCount = redirectCount;
    this.feeling = feeling;
    this.photos = photos;
    this.trail = trail;
  }

  formatDuration(): string {
    const h = Math.floor(this.duration / 3600);
    const m = Math.floor((this.duration % 3600) / 60);
    const s = this.duration % 60;
    if (h > 0) {
      return `${h}小时${m}分`;
    }
    if (m > 0) {
      return s > 0 ? `${m}分${s}秒` : `${m}分钟`;
    }
    return `${s}秒`;
  }

  toJSON(): string {
    return JSON.stringify({ 
      id: this.id, 
      date: this.date, 
      duration: this.duration, 
      direction: this.direction, 
      redirectCount: this.redirectCount,
      feeling: this.feeling,
      photos: this.photos,
      trail: this.trail
    });
  }

  static fromJSON(json: string): WalkRecord {
    const data: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
    const photos: string[] = (data['photos'] as string[]) ?? [];
    const trail: TrailPoint[] = (data['trail'] as TrailPoint[]) ?? [];
    const r = new WalkRecord(
      (data['duration'] as number) ?? 0, 
      (data['direction'] as string) ?? '', 
      (data['redirectCount'] as number) ?? 0,
      (data['feeling'] as string) ?? '',
      photos,
      trail
    );
    r.id = (data['id'] as string) ?? r.id;
    r.date = (data['date'] as string) ?? r.date;
    return r;
  }
}
