
let menu_path = "$menu_path"
let pathes = menu_path.split("->")
var SystemEvents = Application('System Events');
var currentApp = SystemEvents.processes.whose({ frontmost: true })[0];
var menuBar = currentApp.menuBars[0];
function walk(menus,index=0) {
    let name = pathes[index];
    for(let i =0;i<menus.length;i++) {
        let menu = menus[i]
        if(menu.name() == name) {
            if(index == pathes.length -1) {
                menu.click()
                return 0
            } else if(index == 0){
                return walk(menu.menuItems(),index+1)
            } else {
                return walk(menu.menus[0].menuItems(),index +1)
            }
        } else  {
            continue        
        }
    }
    return 1
}
let error = walk(menuBar.menus)
console.log(error)