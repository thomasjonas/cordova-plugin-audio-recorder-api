function AudioRecorderAPI() {
}

AudioRecorderAPI.prototype.record = function (successCallback, errorCallback, options) {
  // define options
  var duration = options.duration || null;
  var sampleRate = options.sampleRate || 16000.0;
  var bitRate = options.bitRate || 12000;
  var bitDepth = options.bitDepth || 16; // 8, 16, 24, or 32.
  var numberOfChannels = options.numberOfChannels || 1;
  var audioQuality = options.audioQuality || 'medium'; // min, low, medium, high or max.

  cordova.exec(successCallback, errorCallback, "AudioRecorderAPI", "record", [duration, sampleRate, bitRate, bitDepth, numberOfChannels]);
};

AudioRecorderAPI.prototype.stop = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "AudioRecorderAPI", "stop", []);
};

AudioRecorderAPI.prototype.playback = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "AudioRecorderAPI", "playback", []);
};

AudioRecorderAPI.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }
  window.plugins.audioRecorderAPI = new AudioRecorderAPI();
  return window.plugins.audioRecorderAPI;
};

cordova.addConstructor(AudioRecorderAPI.install);
