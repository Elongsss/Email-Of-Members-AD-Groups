function Search-EmailADGroup {
  #Массивы
  $adgroupmemberarray = New-Object System.Collections.ArrayList
  $email = New-Object System.Collections.ArrayList
  #Цикл для ввода пользователя
  while ($adgroupmemberarray.Count -eq 0) {
    $inputGroups = Read-Host "Введите названия групп"
    if ([string]::IsNullOrWhiteSpace($inputGroups)) {
      Write-Host "Пустая строка, повторите ввод!" -ForegroundColor Red
      continue
    }
    $grouplist = $inputGroups -split '[, ]' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    #Перебор групп из списка групп
    foreach ($groups in $grouplist) {
      try {
        $groupsmember = Get-ADGroupMember -Identity $groups | Select-Object -ExpandProperty SamAccountName -ErrorAction Stop
        [void]$adgroupmemberarray.AddRange($groupsmember) 
      }
      catch {
        Write-Host "$inputGroups не существует. Повторите ввод" -ForegroundColor Red
        break
      }
    }
  }
  #Фильтруем уникальные имена по EmailAddress и ProxyAddresses
  $addresses = $adgroupmemberarray | Select-Object -Unique | Get-ADUser -Properties EmailAddress, ProxyAddresses | ForEach-Object {
    if ($_.ProxyAddresses) {
      $_.ProxyAddresses | 
      Where-Object { $_ -match ".*@Domain\.*" } | 
      ForEach-Object {
        if ($_ -clike "SMTP:*") { 
          [PSCustomObject]@{ Order = 1; Value = ($_ -replace "SMTP:", "") } 
        }
        else { 
          [PSCustomObject]@{ Order = 2; Value = ($_ -replace "smtp:", "") } 
        }
      } | 
      Sort-Object Order | 
      ForEach-Object { $_.Value }
    }
  } 
  [void]$email.AddRange($addresses)
  Write-Host $email
}




