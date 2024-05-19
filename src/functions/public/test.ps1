$Name = @(‘Red’, ‘Yellow’, ‘Puce’, ‘Red’, ‘Yellow’, ‘Puce’)
$Date = @(‘16/03/19’, ‘16/03/19’, ‘16/03/19’, ‘17/03/19’, ‘17/03/19’, ‘16/03/19’)
$test = [pscustomobject] @{
    PSTypeName = 'Wibble'
    Colour     = 'Red'
    Date       = 'Now'
    Message    = 'Something random'
}
$test.pstypenames
$test.PSObject.TypeNames
$Test.PSObject.TypeNames.Insert(0, 'blah')
$test.PSObject.TypeNames
