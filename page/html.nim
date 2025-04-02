import dekao
import "sprae.nim"

let authPage = render:
  tdiv "#authcodeAndButton":
    input "#authInput":
      placeholder "••••••••"
      sValue "authPage.codeInput"
      maxlength "8"
    button:
      sText "l(authPage.action)"
      sOn "click", "() => {authPage.buttonAction()}"
  # Sprae.js does not seem to directly support radio menus, so onclick used as a workaround
  p "#authModeSelectionMenu":
    span ".authModeSelection":
      sText "authPage.action == 'login' ? l('login').toUpperCase() : l('login')"
      sOn "click", "() => {authPage.action = 'login'; authPage.buttonAction = loginFunc}"
    span: say " - "
    span ".authModeSelection":
      sText "authPage.action == 'register' ? l('register').toUpperCase() : l('register')"
      sOn "click", "() => {authPage.action = 'register'; authPage.buttonAction = registerFunc}"
    span: say " - "
    span ".authModeSelection":
      sText "authPage.action == 'delete' ? l('delete').toUpperCase() : l('delete')"
      sOn "click", "() => {authPage.action = 'delete'; authPage.buttonAction = deleteFunc}"
  tdiv:
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

let gamePage = render:
  button:
    sText "l('logout')"
    sOn "click", "() => {logoutFunc()}"
  span:
    sText "l('fullname', [gd.gender, gd.firstname, gd.lastname])"
  h3: sText "l('greeting', [gd.gender, gd.firstname, gd.lastname])"
  p:
    sText "l('moneyIndicator') + gd.money"
  tdiv "#TEMPinfoPanes":
    tdiv "#businessPane":
      tdiv "#buyBusinessButton":
        sText "l('startBusiness')"
        sOn "click", "() => {gamePage.businessInfoPane.action = 'new'}"
      tdiv "#businessList":
        tdiv ".businessListCard":
          sEach "business in gd.businesses"
          sText "business.field"

    tdiv "#businessInfoPane":
      tdiv:
        sIf "gamePage.businessInfoPane.action == 'new'"
        tdiv ".title":
          h3: sText "l('startBusiness')"
          button:
            say "X"
            sOn "click", "() => {gamePage.businessInfoPane.action = ''}"
        tdiv ".content":
          select:
            sValue "gamePage.businessInfoPane.selectedNewBusiness"
            # sWith "{l: l, gamePage: {businessFields: gamePage.businessFields}}"
            option:
              sEach "field, index in gamePage.businessFields"
              sValue "index"
              sText "l('businessField', [field])"
          button:
            sProp "disabled", "gd.money < 5000"
            sOn "click", "() => {gamePage.businessInfoPane.foundBusiness(gamePage.businessInfoPane.selectedNewBusiness)}"
            sText "'Found business for $5000'"


let main* = render:
  say: "<!DOCTYPE html>"
  html:
    head:
      meta:
        charset "utf-8"
      script:
        src "pow.js"
        tdefer "uhuh"
      script:
        src "script.js"
        tdefer "yep"
      link:
        href "style.css"
        rel "stylesheet"
      title: say "Business Road"
    body:
      h1 "#title": sText "l('title')"
      i:
        sIf "loaded"
        q:
          sText "motd"
      # TODO: improve language selector
      tdiv "#langSelection":
        button:
          sOn "click", "() => {changelangFunc('en')}"
          say "English"
        button:
          sOn "click", "() => {changelangFunc('lv')}"
          say "Latviešu"
      hr: discard
      tdiv:
        sIf "!loaded"
        h3: say "Loading..."
        noscript: h3: say "or not? JavaScript seems to be disabled."
        tstyle:
          say "#content {display: none}"
      tdiv "#content":
        # There is probably a more efficient approach than putting each page in a div.
        # Correction: div per page is probably fine, what I probably meant was avoid nesting
        tdiv:
          sIf "curPage == 'guest' && loaded"
          say authPage
        tdiv "#gamePage":
          sIf "curPage == 'game' && loaded"
          say gamePage
