extension KotlinLikeExtension<T extends Object> on T {
  U let<U>(U Function(T it) callback) {
    return callback(this);
  }
}
