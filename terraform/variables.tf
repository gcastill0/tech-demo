/**** **** **** **** **** **** **** **** **** **** **** ****
Prefix is here to emulate a required naming convention.
**** **** **** **** **** **** **** **** **** **** **** ****/
variable "prefix" {
  default = "tech"
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Default tags used to determine the identity and meta-data 
for the deployment. 
**** **** **** **** **** **** **** **** **** **** **** ****/

variable "tags" {
  type = map(any)

  default = {
    Organization = "Data"
    Keep         = "True"
    Owner        = "Gilberto"
    Region       = "US-EAST-1"
    Purpose      = "Tech Exercise"
    Environment  = "Dev"
  }
}