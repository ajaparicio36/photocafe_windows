/// Represents the connection state of the Canon EDSDK camera.
enum CanonConnectionState {
  /// No camera is connected or the service has not been started.
  disconnected,

  /// The service is currently connecting to the camera
  /// (initializing SDK, discovering cameras, opening session, starting live view).
  connecting,

  /// The camera is connected and ready for operation (live view active).
  connected,

  /// The camera was disconnected and the service is automatically attempting
  /// to re-establish the connection.
  reconnecting,

  /// All retry attempts have been exhausted and the connection could not be
  /// established. The UI should offer a manual "Retry" button.
  error,
}
