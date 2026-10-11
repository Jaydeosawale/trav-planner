"""TLS connection options shared by the API and database migrations."""
import ssl

from sqlalchemy.engine import make_url


def database_connection_options(database_url: str):
    url = make_url(database_url)
    mode = url.query.get("ssl")
    if mode in ("verify-full", "verify-ca"):
        tls = ssl.create_default_context()
        if mode == "verify-ca":
            tls.check_hostname = False
        return url.difference_update_query(["ssl"]), {"ssl": tls}
    return url, {}
