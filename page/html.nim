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
      sOn "click", "() => {gamePage.selBusinessIndex = index; gamePage.selInterviewee = null; gamePage.businessInfoPane.action = 'info'}"
      h3:
        sText "l('businessField', [business.field])"
      span:
        sText "'Emp.: ' + Object.keys(business.employees).length + ' - ' + 'Proj.: ' + Object.keys(business.projects).length"

  tdiv "#bizinfo":
    tdiv "#biztitle":
      sIf "gamePage.businessInfoPane.action !== ''"
      button:
        say "X"
        sOn "click", "() => {gamePage.businessInfoPane.action = ''}"
      ttemplate:
        sIf "gamePage.businessInfoPane.action == 'new'"
        h3: sText "l('startBusiness')"
      ttemplate:
        sIf "gamePage.businessInfoPane.action == 'info'"
        h3: sText "l('businessField', [selBusiness?.field])"

    tdiv "#bizcontent":
      ttemplate:
        sIf "gamePage.businessInfoPane.action == 'new'"
        select:
          sValue "gamePage.businessInfoPane.newBusinessType"
          # sWith "{l: l, gamePage: {businessFields: gamePage.businessFields}}"
          option:
            sEach "field, index in data.BusinessField"
            sValue "index"
            sText "l('businessField', [field])"
        button:
          sProp "disabled", "gd.money < 5000"
          sOn "click", "() => {wssend('foundBusiness', [gamePage.businessInfoPane.newBusinessType])}"
          sText "l('startBusinessCost')"
      ttemplate:
        sIf "gamePage.businessInfoPane.action == 'info'"
        tdiv:
          button:
            sText "l('findEmployees')"
            sOn "click", "() => {wssend('findEmployees', [selBusiness?.id])}"
          # Interviewees
          ul:
            li:
              sEach "ntrvw in selBusiness?.interviewees"
              button:
                sText "l('fullname', [ntrvw.gender, ntrvw.firstname, ntrvw.lastname]) + ' - ' + l('proficiency', [ntrvw.proficiency, ntrvw.gender])"
                sOn "click", "() => {gamePage.selInterviewee = ntrvw; gamePage.suggestedSalary = ntrvw.salary}"
              span:
                sText "' - ' + ntrvw.salary + '$/3s'"
          # Selected Interviewee
          span:
            sIf "gamePage?.selInterviewee != null"
            span:
              sText "l('fullname', [gamePage.selInterviewee.gender, gamePage.selInterviewee.firstname, gamePage.selInterviewee.lastname])"
            input:
              sValue "gamePage.suggestedSalary"
            button:
              sText "l('suggestSalary')"
              sOn "click", "() => {wssend('haggleWithInterviewee', [gamePage.selInterviewee.id, selBusiness.id, gamePage.suggestedSalary])}"
            button:
              sText "l('hireEmp')"
              sOn "click", "() => {wssend('hireEmployee', [selBusiness.id, gamePage.selInterviewee.id])}"
          # Employees
          ul:
            li:
              sEach "emply in selBusiness?.employees"
              span:
                sText "l('fullname', [emply.gender, emply.firstname, emply.lastname]) + ' - ' + l('proficiency', [emply.proficiency, emply.gender])"
              span:
                sText "' - ' + emply.salary + '$/3s'"
              button:
                sText "l('fireEmp')"
                sOn "click", "() => {wssend('fireEmployee', [selBusiness.id, emply.id])}"
          # Projects
          br: discard
          select:
            sValue "gamePage.newProjectType"
            option:
              sEach "proj in selBizAvailableProjects"
              sText "l('businessProject', [proj])"
              sValue "data.BusinessProject.findIndex(e => e == proj)"
          button:
            sText "l('startNewProject')"
            sOn "click", "() => {wssend('createProject', [selBusiness.id, gamePage.newProjectType])}"
          ul:
            li:
              sEach "proj, id in selBusiness?.projects"
              sText "l('businessProject', [proj.project]) + ' - ' + proj.quality + '$/12s'"

    tdiv "#bizitemoptions": discard

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
