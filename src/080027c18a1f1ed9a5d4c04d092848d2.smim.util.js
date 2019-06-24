var util = {
    // Convierte el array de SAP BAPIRET2_T al template que necesita el popoover para mostrarse
    convertReturn2PopOver: function (pReturn) {
        var aMessages = [];
        for (var x = 0; x < pReturn.length; x++) {
            switch (pReturn[x].TYPE) {
                case "E": // Error
                    var vMsg = {
                        type: 'Error',
                        title: pReturn[x].MESSAGE,
                        description: pReturn[x].MESSAGE,
                        subtitle: "",
                        counter: 0
                    };
                    aMessages.push(vMsg);
                    break;
                case "S": // Success
                    var vMsg = {
                        type: 'Success',
                        title: pReturn[x].MESSAGE,
                        description: pReturn[x].MESSAGE,
                        subtitle: "",
                        counter: 0
                    };
                    aMessages.push(vMsg);
                    break;
            }

        }
        var oMessages = new sap.ui.model.json.JSONModel(aMessages);
        return oMessages;


    },
    // Crea el objeto POPOver para poderse utilizar en cualquier vista
    createPopOverReturn: function (pModelData, pView) {

        // Creamos el template
        var oMessageTemplate = new sap.m.MessagePopoverItem({
            type: '{type}',
            title: '{title}',
            description: '{description}',
            subtitle: '{subtitle}',
            counter: '{counter}'
        });

        // Creamos el popover
        var oMessagePopover = new sap.m.MessagePopover({
            items: {
                path: '/',
                template: oMessageTemplate
            },
            initiallyExpanded: true
        });

        // Paso el modelo de datos al objeto
        oMessagePopover.setModel(pModelData);

        // Guardo en la vista el numero total de mensajes recuperados. El objetivo es para que se pueda pintar en
        // el icono que muestre el popup

        var viewModel = new sap.ui.model.json.JSONModel();
        viewModel.setData({numMsgReturn: pModelData.getData().length + ''});
        pView.getView().setModel(viewModel);


        return oMessagePopover;

    },
    isEmpty: function (val) {

        // test results
        //---------------
        // []        true, empty array
        // {}        true, empty object
        // null      true
        // undefined true
        // ""        true, empty string
        // ''        true, empty string
        // 0         false, number
        // true      false, boolean
        // false     false, boolean
        // Date      false
        // function  false

        if (val === undefined)
            return true;

        if (typeof (val) == 'function' || typeof (val) == 'number' || typeof (val) == 'boolean' || Object.prototype.toString.call(val) === '[object Date]')
            return false;

        if (val == null || val.length === 0)        // null or 0 length array
            return true;

        if (typeof (val) == "object") {
            // empty object

            var r = true;

            for (var f in val)
                r = false;

            return r;
        }

        return false;
    }
}