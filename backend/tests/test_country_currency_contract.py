from types import SimpleNamespace

from app.modules.country.schema import CountryListResponse


def test_active_country_contract_includes_currency_for_trip_defaults():
    country = SimpleNamespace(
        id='fr', name='France', iso2='FR', flag_url=None,
        is_active=True, currency_code='EUR',
    )
    result = CountryListResponse.model_validate(country).model_dump()
    assert result['currency_code'] == 'EUR'


def test_legacy_country_without_currency_remains_valid():
    result = CountryListResponse.model_validate({
        'id': 'unknown', 'name': 'Unknown', 'iso2': 'XX',
        'flag_url': None, 'is_active': True,
    })
    assert result.currency_code is None
