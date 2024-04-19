function Memory {
    <#
function SizeOfObj {
    param ([Type]$T, [Object]$thevalue, [System.Runtime.Serialization.ObjectIDGenerator]$gen)
    $type = $T
    [int]$returnval = 0
    if ($type.IsValueType) {
        $nulltype = [Nullable]::GetUnderlyingType($type)
        $returnval = [System.Runtime.InteropServices.Marshal]::SizeOf($nulltype ?? $type)
    } elseif ($null -eq $thevalue) {
        return 0
    } elseif ($thevalue.GetType().Name -eq 'String') {
        $returnval = ([System.Text.Encoding]::Default).GetByteCount([String]$thevalue)
    } elseif (
        $type.IsArray -and
        $type.GetElementType().IsValueType
    ) {
        $returnval = $thevalue.GetLength(0) * [System.Runtime.InteropServices.Marshal]::SizeOf($type.GetElementType())
    } elseif ($thevalue.GetType.Name -eq 'Stream') {
        [System.IO.Stream]$stream = [System.IO.Stream]$thevalue
        $returnval = [int]($stream.Length)
    } elseif ($type.IsSerializable) {
        try {
            [System.IO.MemoryStream]$s = [System.IO.MemoryStream]::new()
            [System.Runtime.Serialization.Formatters.Binary.BinaryFormatter]$formatter = [System.Runtime.Serialization.Formatters.Binary.BinaryFormatter]::new()
            $formatter.Serialize($s, $thevalue)
            $returnval = [int]($s.Length)
        } catch { }
    } elseif ($type.IsClass) {
        $returnval += SizeOfClass -thevalue $thevalue -gen ($gen ?? [System.Runtime.Serialization.ObjectIDGenerator]::new())
    }
    if ($returnval -eq 0) {
        try {
            $returnval = [System.Runtime.InteropServices.Marshal]::SizeOf($thevalue)
        } catch { }
    }
    return $returnval
}
function SizeOf {
    param ($T, $value)
    SizeOfObj -T ($T.GetType()) -thevalue $value -gen $null
}
function SizeOfClass {
    param (
        [Object]$thevalue, [System.Runtime.Serialization.ObjectIDGenerator]$gen
    )
    [bool]$isfirstTime = $null
    $gen.GetId($thevalue, [ref]$isfirstTime)
    if (-not $isfirstTime) { return 0 }
    $fields = $thevalue.GetType().GetFields([System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)

    [int]$returnval = 0
    for ($i = 0; $i -lt $fields.Length; $i++) {
        [Type]$t = $fields[$i].FieldType
        [Object]$v = $fields[$i].GetValue($thevalue)
        $returnval += 4 + (SizeOfObj -T $t -thevalue $v -gen $gen)
    }
    return $returnval
}

$Test = @{}

$n = 1000000
$i = 0
while ($i -lt $n) {
    $Test[$i] = [pscustomobject]@{prop1 = 'blah'}
    $i++
}
$Size = (SizeOf -t [Hashtable] -value $Test)/1KB
"$Size KiB"
#>
}
