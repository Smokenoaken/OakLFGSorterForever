"""Post a published GitHub release to the configured Discord channel."""
import json
import os
import re
import subprocess
import urllib.request
import urllib.error


def payload_for(release):
    tag = release['tagName']
    # Existing release bodies contain the whole changelog; select only this version.
    sections = re.split(r'(?m)^#{1,2}\s+v?', release.get('body') or '')
    notes = next((s.split('\n', 1)[1].strip() for s in sections
                  if '\n' in s and s.split('\n', 1)[0].strip() == tag.removeprefix('v')),
                 (release.get('body') or 'See the GitHub release for details.').strip())
    return {
        'username': 'Oak LFG Sorter Forever Releases',
        'allowed_mentions': {'parse': []},
        'embeds': [{
            'title': f'New Update: Oak LFG Sorter Forever {tag}',
            'url': release['url'],
            'description': notes[:3500],
            'color': 9734857,
            'fields': [{
                'name': 'Downloads',
                'value': '[GitHub](' + release['url'] + ')\n'
                         '[CurseForge](https://www.curseforge.com/wow/addons/oak-lfg-sorter-forever)\n'
                         '[Wago](https://addons.wago.io/addons/oaklfgsorterforever)',
            }, {
                'name': 'Availability',
                'value': 'Available on GitHub. Marketplace processing and approval may take longer.',
            }],
        }],
    }


def main():
    webhook = os.environ.get('DISCORD_WEBHOOK_URL', '')
    if not webhook:
        raise SystemExit('DISCORD_WEBHOOK_URL is missing; no announcement sent.')
    release = json.loads(subprocess.check_output([
        'gh', 'release', 'view', os.environ['RELEASE_TAG'],
        '--repo', os.environ['GITHUB_REPOSITORY'],
        '--json', 'tagName,url,body,isDraft,assets',
    ], text=True))
    if release['isDraft'] or not release['assets']:
        raise SystemExit('Release must be published with a download asset before announcing.')
    request = urllib.request.Request(
        webhook, data=json.dumps(payload_for(release)).encode(),
        headers={'Content-Type': 'application/json', 'User-Agent': 'OakForeverRelease/1.0'},
        method='POST',
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            print(f'Discord accepted announcement (HTTP {response.status}).')
    except urllib.error.HTTPError as error:
        raise SystemExit(f'Discord rejected announcement (HTTP {error.code}).') from None
    except urllib.error.URLError:
        raise SystemExit('Discord request failed; check delivery before retrying.') from None


if __name__ == '__main__':
    main()
