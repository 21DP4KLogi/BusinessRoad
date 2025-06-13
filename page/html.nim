import dekao
import "sprae.nim"

let authPage = render:
  input "#authInput":
    placeholder "••••••••"
    sValue "authPage.codeInput"
    maxlength "8"
  tdiv "#authmodesel":
    span ".authModeSelection":
      sText "authPage.action == 'login' ? l('login').toUpperCase() : l('login')"
      sOn "click", "() => {authPage.action = 'login'; authPage.buttonAction = loginFunc}"
    span ".authModeSelection":
      sText "authPage.action == 'register' ? l('register').toUpperCase() : l('register')"
      sOn "click", "() => {authPage.action = 'register'; authPage.buttonAction = registerFunc}"
    span ".authModeSelection":
      sText "authPage.action == 'delete' ? l('delete').toUpperCase() : l('delete')"
      sOn "click", "() => {authPage.action = 'delete'; authPage.buttonAction = deleteFunc}"
  tdiv "#authreg":
    sIf "authPage.action == 'register'"
    button:
      say "<->"
      sOn "click", "() => {authPage.selGender = authPage.selGender == 'M' ? 'F' : 'M'}"
    select:
      sValue "authPage.selFname"
      # sWith "{list: authPage.namelist('firstname')}"
      option:
        sEach "fname in authPage.namelist('firstname')"
        sValue "fname[0]"
        sText "fname[1]"
    select:
      sValue "authPage.selLname"
      # sWith "{list: authPage.namelist('lastname')}"
      option:
        sEach "lname in authPage.namelist('lastname')"
        sValue "lname[0]"
        sText "lname[1]"
  button "#authbutton":
    sText "l(authPage.action)"
    sOn "click", "() => {authPage.buttonAction()}"
    

let gamePage = render:

  tdiv "#bizlist":
    tdiv "#buybizbutton":
      sText "l('startBusiness')"
      sOn "click", "() => {gamePage.openNewBizMenu()}"

    tdiv ".bizcard":
      sEach "business, index in gd.businesses"
      sOn "click",
        "() => {gamePage.selBusinessIndex = index; gamePage.unselectBizItem();" &
        " gamePage.businessInfoPane.action = 'info'}"
      h3:
        sText "l('businessField', [business.field])"
      span:
        sText "'Emp.: ' + Object.keys(business.employees).length + ' - ' + 'Proj.: ' + Object.keys(business.projects).length"

  tdiv "#bizinfo":
    tdiv "#biztitle":
      sIf "gamePage.businessInfoPane.action !== ''"
      button:
        say "X"
        sOn "click", "() => {gamePage.businessInfoPane.action = '', gamePage.unselectBizItem()}"
      ttemplate:
        sIf "gamePage.businessInfoPane.action == 'new'"
        h3: sText "l('startBusiness')"
      ttemplate:
        sIf "gamePage.businessInfoPane.action == 'info'"
        h3: sText "l('businessField', [selBusiness.field])"

    tdiv "#bizcontent":
      tdiv "#bizcontent-new":
        sIf "gamePage.businessInfoPane.action == 'new'"
        tdiv:
          button:
            sEach "field, index in data.BusinessField.map(e => e)"
            sText "l('businessField', [field])"
            sClass "{'selected': gamePage.businessInfoPane.newBusinessType == index}"
            sOn "click", "() => {gamePage.businessInfoPane.newBusinessType = index}"
        button:
          sProp "disabled", "gd.money < 5000 || gamePage.businessInfoPane.newBusinessType == -1"
          sOn "click", "() => {wssend('foundBusiness', [gamePage.businessInfoPane.newBusinessType])}"
          sText "l('startBusinessCost')"
      tdiv "#bizcontent-info":
        sIf "gamePage.businessInfoPane.action == 'info'"
        # Interviewees
        tdiv "#infotab-interviewees":
          p ".divtabtitle": sText "l('interviewees')"
          button ".divtabtopcontent":
            sText "l('findEmployees')"
            sOn "click", "() => {wssend('findEmployees', [selBusiness.id])}"
          tdiv:
            sEach "ntrvw in selBusiness.interviewees"
            button:
              sText:
                "l('fullname', [ntrvw.gender, ntrvw.firstname, ntrvw.lastname]) " & 
                " + ' - ' + l('proficiency', [ntrvw.proficiency, ntrvw.gender]) " &
                " + ' - ' + ntrvw.salary + '$/12s'"
              sOn "click", "() => {gamePage.selInterviewee = ntrvw.id; gamePage.suggestedSalary = ntrvw.salary}"
              sClass "{'selected': gamePage.selBizItem.id == ntrvw.id && gamePage.selBizItem.action == 'I'}"
        # Employees
        tdiv "#infotab-employees":
          p ".divtabtitle": sText "l('employees')"
          tdiv:
            sEach "emply in selBusiness.employees"
            button:
              sText:
                "l('fullname', [emply.gender, emply.firstname, emply.lastname]) " & 
                "+ ' - ' + l('proficiency', [emply.proficiency, emply.gender]) " &
                "+ ' - ' + emply.salary + '$/12s'"
              sOn "click", "() => {gamePage.selEmployee = emply.id}"
              sClass "{'selected': gamePage.selBizItem.id == emply.id && gamePage.selBizItem.action == 'E'}"
        # Projects
        tdiv "#infotab-projects":
          p ".divtabtitle": sText "l('projects')"
          select ".divtabtopcontent":
            sValue "gamePage.newProjectType"
            option:
              sEach "proj in selBizAvailableProjects"
              sText "l('businessProject', [proj])"
              sValue "data.BusinessProject.findIndex(e => e == proj)"
          button ".divtabtopcontent":
            sText "l('startNewProject')"
            sOn "click", "() => {wssend('createProject', [selBusiness.id, gamePage.newProjectType])}"
          tdiv:
            sEach "proj, id in selBusiness.projects"
            button:
              sText:
                "l('businessProject', [proj.project])" &
                "+ ' - ' + proj.quality + '$/3s'" &
                "+ ' - ' + (proj.active ? 'Active' : 'Inactive')"
              sOn "click", "() => {gamePage.selProject = id}"
              sClass "{'selected': gamePage.selBizItem.id == id && gamePage.selBizItem.action == 'P'}"

    tdiv "#bizitemoptions":
      # Selected Interviewee
      sIf "gamePage.selBizItem.action != 'N'"
      tdiv "#bizitemoptions-title":
        button:
          say "X"
          sOn "click", "() => {gamePage.unselectBizItem()}"

        ttemplate:
          sIf "gamePage.selBizItem.action == 'I'"
          h3:
            # Just checking if undefined, too buggy otherwise
            sText "selInterviewee && l('fullname', [selInterviewee.gender, selInterviewee.firstname, selInterviewee.lastname])"

        ttemplate:
          sIf "gamePage.selBizItem.action == 'E'"
          h3:
            sText "selEmployee && l('fullname', [selEmployee.gender, selEmployee.firstname, selEmployee.lastname])"

        ttemplate:
          sIf "gamePage.selBizItem.action == 'P'"
          h3:
            sText "selProject && l('businessProject', [selProject.project])"

      tdiv:
        sIf "gamePage.selBizItem.action == 'I'"
        input:
          sValue "gamePage.suggestedSalary"
        button:
          sText "l('suggestSalary')"
          sOn "click", "() => {wssend('haggleWithInterviewee', [gamePage.selBizItem.id, selBusiness.id, gamePage.suggestedSalary])}"
        button:
          sText "l('hireEmp')"
          sOn "click", "() => {wssend('hireEmployee', [selBusiness.id, gamePage.selBizItem.id])}"
      tdiv:
        sIf "gamePage.selBizItem.action == 'E'"
        button:
          sText "l('fireEmp')"
          sOn "click", "() => {wssend('fireEmployee', [selBusiness.id, gamePage.selBizItem.id])}"
      tdiv:
        sIf "gamePage.selBizItem.action == 'P'"
        p: sText "selProject && selProject.quality + '$/3s'"
        button:
          sText "'Scrap project'"
          sOn "click",
            "() => {wssend('dproj', [selBusiness.id, selProject.id])}"
        button:
          sText "'Toggle active'"
          sOn "click",
            "() => {wssend('wprojactive', [selBusiness.id, selProject.id, selProject.active ? 'F' : 'T'])}"

let main* = render:
  say: "<!DOCTYPE html>"
  html:
    head:
      meta:
        charset "utf-8"
      script:
        src "script.js"
        tdefer "yep"
      link:
        href "style.css"
        rel "stylesheet"
      title: say "Business Road"
    body:
      tdiv "#topbar":
        span ".left":
          h1: sText "l('title')"
          q:
            sIf "loaded"
            sText "motd"
        span ".right":
          select "#langsel":
            sValue "langcode"
            option:
              say "English"
              value "en"
            option:
              say "Latviešu"
              value "lv"
          select "#themesel":
            sValue "colortheme"
            sOn "change", "() => {setColorsToTheme(colortheme)}"
            option:
              sText "l('colortheme', ['light'])"
              value "light"
            option:
              sText "l('colortheme', ['dark'])"
              value "dark"
            option:
              sText "l('colortheme', ['gruvbox'])"
              value "gruvbox"
          button:
            sIf "curPage == 'game' && loaded"
            sText "l('logout')"
            sOn "click", "() => {logoutFunc()}"
          span:
            sIf "curPage == 'game' && loaded"
            sText "l('fullname', [gd.gender, gd.firstname, gd.lastname])"
      tdiv "#infobar":
        p "#moneycount":
          sIf "curPage == 'game' && loaded"
          sText "l('moneyIndicator') + gd.money"
      tdiv "#main":
        tdiv "#loading":
          sIf "!loaded"
          h3: say "Loading..."
          noscript: h3: say "or not? JavaScript seems to be disabled."
          tstyle:
            say "#authpage, #gamepage {display: none}"
        tdiv "#authpage":
          sIf "curPage == 'guest' && loaded"
          say authPage
        tdiv "#gamepage":
          sIf "curPage == 'game' && loaded"
          say gamePage
