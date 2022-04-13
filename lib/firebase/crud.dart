import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:location/location.dart' as loc;

FirebaseFirestore _firestore = FirebaseFirestore.instance;
Geoflutterfire _geo = Geoflutterfire();
// Location _location = Location();
loc.Location _location = loc.Location();

var userCollection = _firestore.collection("User");
var groupCollection = _firestore.collection('Groups');

void addUserData(String name, String email) async {
  var doc = await _firestore.collection('User').add({});

  bool locationEnabled = await _location.serviceEnabled();
  var permissionGranted = await _location.hasPermission();
  late Position currentPosition;
  if (permissionGranted == loc.PermissionStatus.granted && locationEnabled) {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;
  } else {
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
    } else {
      throw Exception(
          'User cannot be created. \n Please check location settings.');
    }
  }

  GeoFirePoint point = _geo.point(
      latitude: currentPosition.latitude, longitude: currentPosition.longitude);

  await _firestore.collection('User').doc(doc.id).set({
    'UID': doc.id,
    'UserEmail': email,
    'UserName': name,
    'GroupList': [],
    'Requests': [],
    'Location': point.data,
    'AlertMessages': []
  });
}

Future<String> createGroup(
    String groupName, String email, List<Map<String, String>> requested) async {
  var if_group_exist = await _firestore
      .collection('Groups')
      .where('GroupName', isEqualTo: groupName)
      .get();

  if (if_group_exist.docs.isNotEmpty) {
    return "Group is already created";
  }
  var user1 = await _firestore
      .collection('User')
      .where('UserEmail', isEqualTo: email)
      .get();
  late String uid = '';
  late String admin = '';
  for (var data in user1.docs) {
    uid = data['UID'];
    admin = data['UserName'];
  }

  var group = await _firestore.collection('Groups').add({});
  _firestore.collection('Groups').doc(group.id).set({
    'GID': group.id,
    'GroupName': groupName,
    'Requested': requested,
    'Admin': admin,
  });

  updateUserInMembersList(group.id, uid);
  addGroupToGroupList(uid, admin, groupName, group.id);
  addMemberToGroup(admin, groupName, group.id, requested);

  return "";
}

void updateUserInMembersList(String GID, String UID) async {
  var user = await userCollection.doc(UID).get();
  var userData = user.data()!;
  var location = userData['Location']['geopoint'];
  String email = userData['UserEmail'];
  String name = userData['UserName'];

  GeoFirePoint point =
      _geo.point(latitude: location.latitude, longitude: location.longitude);

  var groupData =
      _firestore.collection('Groups').doc(GID).collection('MembersList');

  dynamic map = {
    'Email': email,
    'Name': name,
    'Location': point.data,
    'UID': UID,
  };
  late String Id;
  var getData = await groupData.get();
  var data = getData.docs.where((element) => element['Email'] == map['Email']);
  if (data.isEmpty) {
    var doc = await groupData.add({});
    map['MID'] = doc.id;
    groupData.doc(doc.id).set(map);
  }
}

void addGroupToGroupList(
    String UID, String admin, String groupName, String GID) async {
  var userData = await userCollection.doc(UID).get();
  var keys = userData.data()!;
  List groupList = keys['GroupList'];

  dynamic map = {
    'Admin': admin,
    'GID': GID,
    'GroupName': groupName,
  };

  for (var group in groupList) {
    if (group['GID'] == map['GID']) {
      // throw 'Group Already Exists';
      return;
    }
  }

  groupList.add(map);
  // print(groupList);
  userCollection.doc(UID).update({
    'GroupList': groupList,
  });
}

void addMemberToGroup(String admin, String groupName, String GID,
    List<Map<String, String>> requested) async {
  for (var i in requested) {
    var user = await _firestore
        .collection('User')
        .where('UserEmail', isEqualTo: i['Email'])
        .get();
    late String UID = '';
    for (var data in user.docs) {
      UID = data['UID'];
    }
    try {
      addUserToRequests(UID, admin, groupName, GID);
    } catch (e) {
      print(e);
    }
  }
}

void addUserToRequests(
    String UID, String admin, String groupName, String GID) async {
  var userData = await _firestore.collection('User').doc(UID).get();
  var keys = userData.data()!;
  List requests = keys['Requests'];
  dynamic map = {
    'Admin': admin,
    'GID': GID,
    'GroupName': groupName,
  };
  for (var group in requests) {
    if (group['GID'] == map['GID']) {
      // throw 'Group Already Exists';
      return;
    }
  }
  requests.add(map);
  // print(requests);
  _firestore.collection("User").doc(UID).update({
    'Requests': requests,
  });
}

// from user as well as from group
void deleteFromRequest(String GID, String UID, String email) async {
  var user = await userCollection.doc(UID).get();
  var userData = user.data()!;

  List request = userData['Requests'];
  request.removeWhere((element) => element['GID'] == GID);
  userCollection.doc(UID).update({
    'Requests': request,
  });

  var group = await groupCollection.doc(GID).get();
  var groupData = group.data()!;

  List requested = groupData['Requested'];
  requested.removeWhere((element) => element['Email'] == email);
  groupCollection.doc(GID).update({
    'Requested': requested,
  });
}

void alertInGroup(String gid, String AlertEmail) async {
  var group = await groupCollection.doc(gid).collection("MembersList").get();

  var doc = await groupCollection
      .doc(gid)
      .collection("MembersList")
      .where("Email", isEqualTo: AlertEmail)
      .get();

  late String Name;
  var location;
  for (var i in doc.docs) {
    Name = i['Name'];
    location = i['Location']['geopoint'];
  }

  GeoFirePoint point =
      _geo.point(latitude: location.latitude, longitude: location.longitude);

  String UID;
  String address = await getAddresFromLatLng(location);

  print(address);
  for (var i in group.docs) {
    if (i['Email'] != AlertEmail) {
      String email = i['Email'];
      var userDoc = await _firestore
          .collection("User")
          .where("UserEmail", isEqualTo: email)
          .get();
      for (var it in userDoc.docs) {
        List alerts = it['AlertMessages'];
        UID = it['UID'];
        print(it);

        dynamic map = {
          "GID": gid,
          "Name": Name,
          "Location": point.data,
          "Address": address,
          "Email": AlertEmail,
        };

        for (var x in alerts) {
          if (x['GID'] == map['GID']) {
            // already exists
            return;
          }
        }
        alerts.add(map);
        await userCollection.doc(UID).update({"AlertMessages": alerts});
      }
    }
  }
}

Future<String> getAddresFromLatLng(GeoPoint location) async {
  List<Placemark> placemark =
      await placemarkFromCoordinates(location.latitude, location.longitude);

  Placemark place = placemark[0];

  String address =
      "${place.street}, ${place.locality}\n                 ${place.subAdministrativeArea}, ${place.administrativeArea}\n"
      "                 ${place.postalCode}"
      "\n                 ${place.country}";
  print(address);

  return address;
}

void deleteFromAlertMessages(String UID, String email) async {
  var user = await userCollection.doc(UID).get();
  var userData = user.data()!;

  List alert = userData['AlertMessages'];
  alert.removeWhere((element) => element['Email'] == email);
  userCollection.doc(UID).update({
    'AlertMessages': alert,
  });
}
