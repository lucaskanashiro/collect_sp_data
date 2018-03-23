# encoding=utf8
import sys
reload(sys)
sys.setdefaultencoding('utf8')
import utm
import requests
import json
from scipy import spatial
from xml.dom import minidom
from pymongo import MongoClient
import subprocess

def load_nodes_from_xml(content):
    """
    Extract x,y from every node in a xml string

    >>> load_nodes_from_xml("<node id='1001237099' x='2819741.636735585' y='7204646.500622427'/>")
    [[2819741.636735585, 7204646.500622427]]
    """
    nodes = content.getElementsByTagName('node')
    mylist = []
    for u in nodes:
        mylist.append(
            [float(u.getAttribute("x")), float(u.getAttribute("y"))])
    return mylist


def coordinates_from_xml(path):
    """
    Load coordinates from xml file

    >>> coordinates_from_xml("map.xml")
    [[2819741.636735585, 7204646.500622427]]
    """
    return load_nodes_from_xml(
            minidom.parse(path))


def closest_point(kd_tree, point, points):
    distance, closest_neighbor = kd_tree.query([point])
    idx = closest_neighbor[0]
    return points[idx]


def mount_kd_tree(points):
    return spatial.KDTree(points)


def olho_vivo_get_auth(token):
    url = "http://api.olhovivo.sptrans.com.br/v2.1/Login/Autenticar?token={0}"\
            .format(token)
    cookies = requests.post(url).cookies
    return cookies.get_dict()['apiCredentials']


def request_buses(auth):
    url = "http://api.olhovivo.sptrans.com.br/v2.1/Posicao"
    resp = requests.get(url, cookies={"apiCredentials": auth})
    return json.loads(resp.text)


def geo_to_xy(coordinate):
    x, y, _, _ = utm.from_latlon(coordinate[0], coordinate[1])
    return [x,y]


def bus_data_from_geo_to_xy(data):
    return map(geo_to_xy, data)


mytoken = subprocess\
            .Popen(["cat", "/tmp/.olho_vivo_api"], stdout=subprocess.PIPE)\
            .stdout\
            .read()\
            .strip()

auth = olho_vivo_get_auth(mytoken)
buses_data = request_buses(auth)
pts = coordinates_from_xml("map.xml")
tree = mount_kd_tree(pts)
client = MongoClient()
db = client['sp']
collection = db['olho_vivo']


for bus_line in buses_data['l']:
    for vehicle in bus_line['vs']:
        rounded_point = closest_point(
            tree, geo_to_xy([vehicle['px'], vehicle['py']]), pts)
        doc = {
            'prefix': vehicle['p'],
            'lat': vehicle['py'],
            'lon': vehicle['px'],
            'timestamp': vehicle['ta'],
            'display': bus_line['c'],
            'line_identifier': bus_line['cl'],
            'direction': bus_line['sl'],
            'display_origin': bus_line['lt0'],
            'display_destination': bus_line['lt1'],
            'vehicles_count': bus_line['qv'],
            'rounded_x': rounded_point[0],
            'rounded_y': rounded_point[1]
        }
        collection.insert_one(doc)
