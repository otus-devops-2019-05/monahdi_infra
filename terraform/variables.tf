variable project {
  description = "Project ID"
}

variable region {
  description = "Region"

  # Значение по умолчанию
  default = "europe-west1"
}

variable public_key-path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}

variable disk_image {
  description = "Disk image"
}

variable privat_key {
  description = "Connection privat key"
}

variable zone {
  description = "Zone"

  #Значение по умолчанию
  default = "europe-west1-d"
}
