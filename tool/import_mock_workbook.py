"""将用户提供的工作簿及图片导入打包初始化样本，不改写运行中账号文件。"""
import argparse
import hashlib
import json
import re
import shutil
from pathlib import Path
from zipfile import ZipFile
import xml.etree.ElementTree as ET

NS = {'m': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
ROOT = Path(__file__).resolve().parents[1]
CATEGORIES = {'美食': 'food', '探店': 'shops', '户外': 'outdoors', '运动': 'sports',
              '旅游': 'travel', '摄影': 'photo', '研学': 'study', '桌游': 'games'}


def workbook(path):
    result = {}
    with ZipFile(path) as archive:
        strings = []
        if 'xl/sharedStrings.xml' in archive.namelist():
            strings = [''.join(n.itertext()) for n in ET.fromstring(archive.read('xl/sharedStrings.xml')).findall('m:si', NS)]
        rels = {r.attrib['Id']: r.attrib['Target'] for r in ET.fromstring(archive.read('xl/_rels/workbook.xml.rels'))}
        for sheet in ET.fromstring(archive.read('xl/workbook.xml')).find('m:sheets', NS):
            target = rels[sheet.attrib['{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id']]
            target = target.lstrip('/') if target.startswith('/') else 'xl/' + target
            rows = []
            for row in ET.fromstring(archive.read(target)).findall('m:sheetData/m:row', NS):
                cells = {}
                for cell in row:
                    value = cell.find('m:v', NS)
                    text = value.text if value is not None else ''
                    if cell.attrib.get('t') == 's':
                        text = strings[int(text)]
                    elif cell.attrib.get('t') == 'inlineStr':
                        text = ''.join(cell.find('m:is', NS).itertext())
                    cells[re.sub(r'\d+', '', cell.attrib['r'])] = text or ''
                if any(cells.values()):
                    rows.append(cells)
            headers = rows[0]
            result[sheet.attrib['name']] = [{label: row.get(col, '') for col, label in headers.items()} for row in rows[1:]]
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, required=True)
    args = parser.parse_args()
    source = args.source
    xlsx = source / '搭子App模拟数据.xlsx'
    data = workbook(xlsx)
    media = {p.name: p for p in (source / 'assets').iterdir() if p.is_file() and p.suffix.lower() in {'.jpg', '.jpeg', '.png', '.webp'}}
    refs = set()

    def image(value):
        if not value:
            return ''
        filename = Path(value).name
        if filename not in media:
            raise ValueError(f'缺少图片: {value}')
        refs.add(filename)
        return 'assets/mock/media/' + filename

    def photos(row, keys):
        return [image(row[k]) for k in keys if row.get(k)]

    def split(value):
        return [v.strip() for v in re.split('[、，,;；]', value) if v.strip()]

    old_catalog = json.loads((ROOT / 'assets/mock/home/catalog.json').read_text())
    old_feed = json.loads((ROOT / 'assets/mock/square/feed.json').read_text())
    activities = []
    for r in data['活动数据']:
        activities.append(dict(id=r['活动ID'], ownerId=r['发布者用户ID'], title=r['主标题'],
            category=r['活动类型'], categoryId=CATEGORIES[r['活动类型']], description=r['性别限制'],
            gender=r['性别限制'], time=r['发布时间'], location=r['发布地点'],
            image=image(r['活动图片文件路径']), avatar=image(r['活动头像文件路径']),
            photos=photos(r, ['活动图片文件路径', '活动图片2文件路径', '活动图片3文件路径'])))
    users = []
    for r in data['用户列表']:
        users.append(dict(id=r['用户ID'], name=r['昵称'], gender=r['性别'],
            age=int(r['年龄']), heightCm=int(r['身高(cm)']), weightKg=int(r['体重(kg)']),
            city=r['地区'], signature=r['个性签名'], interests=split(r['Ta的兴趣']), tags=split(r['Ta的标签']),
            avatar=image(r['头像文件路径']), photos=photos(r, ['相册图片1文件路径', '相册图片2文件路径', '相册图片3文件路径']),
            categoryIds=list(dict.fromkeys(a['categoryId'] for a in activities if a['ownerId'] == r['用户ID']))))
    user_ids = {u['id'] for u in users}
    assert len(user_ids) == len(users), '重复用户ID'
    assert len({a['id'] for a in activities}) == len(activities), '重复活动ID'
    assert all(a['ownerId'] in user_ids for a in activities), '活动发布人缺失'
    old_posts = {p['id']: p for p in old_feed['posts']}
    by_activity = {a['id']: a for a in activities}
    posts = []
    for r in data['动态数据']:
        assert r['用户ID'] in user_ids, '动态作者缺失'
        post = dict(id=r['动态ID'], authorId=r['用户ID'], author=r['昵称'], avatar=image(r['发布者头像文件路径']),
            text=r['动态文本'], photos=photos(r, ['动态图片文件路径']), location=r['地区'], category=r['活动类型'],
            isMine=False, likeCount=0, commentCount=0)
        # 仅保留已有且作者一致的关联，不从文案猜测新活动ID。
        linked = old_posts.get(post['id'], {}).get('activityId')
        if linked in by_activity and by_activity[linked]['ownerId'] == post['authorId']:
            post['activityId'] = linked
        posts.append(post)
    assert len({p['id'] for p in posts}) == len(posts), '重复动态ID'
    account_path = ROOT / 'assets/mock/user/account.json'
    account = json.loads(account_path.read_text())
    initial_user = next(u for u in users if u['id'] == 'U001')
    account['profile'].update({k: initial_user[k] for k in ['id', 'name', 'avatar', 'signature', 'gender', 'age', 'city', 'interests', 'tags']})
    my_activities = [dict(id=a['id'], title=a['title'], cover=a['image'], status='unknown', category=a['category'],
        joined=False, time=a['time'], location=a['location'], description=a['description']) for a in activities if a['ownerId'] == 'U001']
    outputs = {
        'home/catalog': dict(categories=old_catalog['categories'], companions=users, activities=activities),
        'square/feed': dict(posts=posts, likes=[], comments={}, following=[]),
        'user/account': account,
        'user/interests': [dict(type=r['标签类别'], label=r['标签值']) for r in data['兴趣标签库']],
        'activity/my_activities': my_activities,
    }
    # 全部校验成功后才写入工程；用户磁盘账号不在此脚本范围内。
    for filename, path in media.items():
        dest = ROOT / 'assets/mock/media' / filename
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, dest)
    for name, value in outputs.items():
        (ROOT / 'assets/mock' / (name + '.json')).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')
    report = dict(source=str(xlsx), sha256=hashlib.sha256(xlsx.read_bytes()).hexdigest(),
        users=len(users), activities=len(activities), posts=len(posts), interests=len(data['兴趣标签库']),
        copiedImages=len(media), referencedImages=len(refs), outputs=list(outputs),
        note='公开目录包含所有用户；既有磁盘快照保留。发布时间不作为活动排期，未生成报名/消息/认证记录。')
    dest = ROOT / 'docs/data/import-2026-11-10.json'
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(report, ensure_ascii=False))


if __name__ == '__main__':
    main()
