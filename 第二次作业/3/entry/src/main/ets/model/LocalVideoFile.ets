/*
 * Local Video File Model
 * Represents a video file selected from local storage
 */

export class LocalVideoFile {
  name: string = '';
  uri: string = '';

  constructor(name: string, uri: string) {
    this.name = name;
    this.uri = uri;
  }
}
