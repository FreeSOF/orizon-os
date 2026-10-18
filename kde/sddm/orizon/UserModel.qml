import QtQuick 2.15

// Robust user list for the ORIZON greeter.
//
// Previous version built the list only when `customUserModel.count ===
// userModel.count` and looked the selected name up with an uninitialised
// `var index`. If the last user was not found (or the Repeater had not
// finished yet) the list ended up EMPTY, the avatar click hid the password
// field and the user got stuck on a blank screen — which is why login worked
// "sometimes". Now the list is rebuilt after every change and always falls
// back to the first user.
Item {
    id: root

    property alias usersList: usersList
    property string lastNameUser: userModel.lastUser
    property string finalLoginUserName: ""
    property url lastUrlAvatar

    function rebuild() {
        var n = customUserModel.count
        if (n === 0)
            return

        // find selected user, default to the first one
        var sel = 0
        for (var i = 0; i < n; i++) {
            if (customUserModel.get(i).name === lastNameUser) {
                sel = i
                break
            }
        }

        finalLoginUserName = customUserModel.get(sel).name
        lastUrlAvatar = customUserModel.get(sel).icon

        // selected user first, the rest after it
        usersList.clear()
        for (var k = 0; k < n; k++) {
            var item = customUserModel.get((sel + k) % n)
            usersList.append({ name: item.name, icon: item.icon })
        }
    }

    Repeater {
        model: userModel
        delegate: Item {
            Component.onCompleted: {
                customUserModel.append({ name: model.name, icon: model.icon })
                root.rebuild()
            }
        }
    }

    onLastNameUserChanged: rebuild()
    Component.onCompleted: rebuild()

    ListModel { id: customUserModel }
    ListModel { id: usersList }
}
