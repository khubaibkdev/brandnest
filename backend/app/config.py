from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+psycopg://brandnest:brandnest@localhost:5432/brandnest"
    # The deals desk signs every verification with `admin_user`, so use a real
    # name. Both MUST be overridden before the API is reachable from outside the
    # machine (RUNBOOK §2).
    admin_user: str = "founder"
    admin_password: str = "brandnest"
    crawler_user_agent: str = "BrandNestBot/0.1 (+contact: tools@emaago.com)"
    crawler_delay_seconds: float = 3.0
    # Firebase service-account JSON used to verify the app's ID tokens. The
    # catalog is public, so an absent key only disables the `/me` routes —
    # the rest of the API, and a guest browsing the app, carry on unaffected.
    # Relative to the backend root, which is the working directory both in the
    # container (/code, bind-mounted) and when run locally.
    firebase_credentials_path: str = "secrets/firebase-service-account.json"
    # Search (US-11). An unreachable Meilisearch only disables /search — the
    # rest of the catalog API and the app's other tabs carry on.
    meili_url: str = "http://localhost:7700"
    meili_key: str = "brandnest-dev-key"
    # Community deal screenshots (US-14). A local volume until R2 exists —
    # see services/uploads.py for why they are not in Postgres.
    uploads_dir: str = "/data/uploads"
    uploads_url_path: str = "/uploads"
    # Where shared links point (US-21 invites). The ngrok tunnel's HTTPS host
    # until there is a real domain; WhatsApp only makes http(s) links tappable.
    public_base_url: str = "http://localhost:8000"
    # Android App Links: the app opens a shared link only if this host vouches
    # for the app's package and signing certificate(s) in assetlinks.json.
    android_package: str = "pk.brandnest.brandnest"
    android_cert_sha256: list[str] = []


settings = Settings()
