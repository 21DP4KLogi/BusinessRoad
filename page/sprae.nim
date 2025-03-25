import dekao

proc sIf*(value: string) = attr ":if", value
proc sEach*(value: string) = attr ":each", value
proc sText*(value: string) = attr ":text", value
proc sClass*(value: string) = attr ":class", value
proc sStyle*(value: string) = attr ":style", value
proc sValue*(value: string) = attr ":value", value
proc sProp*(prop, value: string) = attr ":" & prop, value
proc sWith*(value: string) = attr ":with", value
proc sFx*(value: string) = attr ":fx", value
proc sRef*(value: string) = attr ":ref", value
proc sOn*(event, value: string) = attr ":on" & event, value

# template ttemplate*(inner) = tag "", "template", inner
