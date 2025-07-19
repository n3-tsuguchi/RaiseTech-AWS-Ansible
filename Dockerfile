# --- ステージ1: ビルドステージ ---
# アプリケーションをビルドするための環境
FROM gradle:8.5-jdk17-focal AS build

# 作業ディレクトリを設定
WORKDIR /home/gradle/project

# Gradleのビルドに必要なファイルを先にコピー
# これにより依存関係のレイヤーがキャッシュされ、2回目以降のビルドが高速化します
COPY build.gradle settings.gradle gradlew ./
COPY gradle ./gradle

# アプリケーションのソースコードをすべてコピー
COPY src ./src

# Gradleラッパーに実行権限を付与
RUN chmod +x ./gradlew

# アプリケーションをビルドして実行可能なJARファイルを作成します
# --no-daemonオプションはCI環境での実行を安定させます
# ここでビルドが失敗した場合は、エラーで処理が停止します
RUN ./gradlew bootJar --no-daemon


# --- ステージ2: 実行ステージ ---
# ビルドされたアプリケーションを実行するための、より軽量な環境
# ベースイメージを openjdk から eclipse-temurin に変更
FROM eclipse-temurin:17-jre-focal

# 作業ディレクトリを設定
WORKDIR /app

# ビルドステージから生成されたJARファイルをコピーします
# ワイルドカード(*)を使っているため、JARファイル名がバージョン等で変わっても対応可能です
COPY --from=build /home/gradle/project/build/libs/*.jar app.jar

# アプリケーションがリッスンするポートを公開
EXPOSE 8080

# コンテナ起動時にアプリケーションを実行するコマンド
ENTRYPOINT ["java", "-jar", "app.jar"]
