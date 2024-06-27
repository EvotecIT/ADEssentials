$Script:Rights = @{
    "Self"                            = @{
        "InheritedObjectAceTypePresent"                       = ""
        "ObjectAceTypePresent"                                = ""
        "ObjectAceTypePresent, InheritedObjectAceTypePresent" = ""
        'None'                                                = ""
    }
    "DeleteChild, DeleteTree, Delete" = @{
        "InheritedObjectAceTypePresent"                       = "DeleteChild, DeleteTree, Delete"
        "ObjectAceTypePresent"                                = "DeleteChild, DeleteTree, Delete"
        "ObjectAceTypePresent, InheritedObjectAceTypePresent" = "DeleteChild, DeleteTree, Delete"
        'None'                                                = "DeleteChild, DeleteTree, Delete"
    }
    "GenericRead"                     = @{
        "InheritedObjectAceTypePresent"                       = "Read Permissions,List Contents,Read All Properties,List"
        "ObjectAceTypePresent"                                = "Read Permissions,List Contents,Read All Properties,List"
        "ObjectAceTypePresent, InheritedObjectAceTypePresent" = "Read Permissions,List Contents,Read All Properties,List"
        'None'                                                = "Read Permissions,List Contents,Read All Properties,List"
    }
    "CreateChild"                     = @{
        "InheritedObjectAceTypePresent"                       = "Create"
        "ObjectAceTypePresent"                                = "Create"
        "ObjectAceTypePresent, InheritedObjectAceTypePresent" = "Create"
        'None'                                                = "Create"
    }
    "DeleteChild"                     = @{
        "InheritedObjectAceTypePresent"                       = "Delete"
        "ObjectAceTypePresent"                                = "Delete"
        "ObjectAceTypePresent, InheritedObjectAceTypePresent" = "Delete"
        'None'                                                = "Delete"
    }
    "GenericAll"                      = @{
        "InheritedObjectAceTypePresent"                       = "Full Control"
        "ObjectAceTypePresent"                                = "Full Control"
        "ObjectAceTypePresent, InheritedObjectAceTypePresent" = "Full Control"
        'None'                                                = "Full Control"
    }
    "CreateChild, DeleteChild"        = @{
        "InheritedObjectAceTypePresent"                       = "Create/Delete"
        "ObjectAceTypePresent"                                = "Create/Delete"
        "ObjectAceTypePresent, InheritedObjectAceTypePresent" = "Create/Delete"
        'None'                                                = "Create/Delete"
    }
    "ReadProperty, WriteProperty"     = @{
        "InheritedObjectAceTypePresent"                       = "Read All Properties;Write All Properties"
        "ObjectAceTypePresent"                                = "Read All Properties;Write All Properties"
        "ObjectAceTypePresent, InheritedObjectAceTypePresent" = "Read All Properties;Write All Properties"
        'None'                                                = "Read All Properties;Write All Properties"
    }
    "WriteProperty"                   = @{
        "InheritedObjectAceTypePresent"                       = "Write All Properties"
        "ObjectAceTypePresent"                                = "Write"
        "ObjectAceTypePresent, InheritedObjectAceTypePresent" = "Write"
        'None'                                                = "Write All Properties"
    }
    "ReadProperty"                    = @{
        "InheritedObjectAceTypePresent"                       = "Read All Properties"
        "ObjectAceTypePresent"                                = "Read"
        "ObjectAceTypePresent, InheritedObjectAceTypePresent" = "Read"
        'None'                                                = "Read All Properties"
    }
}