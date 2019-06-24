var modelSAP = "";

var RESTUtil = {

    /**
     * Funcion que gestiona las peticiones GET genericas a los servicios REST
     */
    callGetRestService: function (url, successHandler, errorHandler) {
        var aData = jQuery.ajax({
            type: "GET",
            contentType: "application/json",
            dataType: 'json',
            url: url,
            async: false,
            success: function (data) {
                successHandler(data);
            },
            error: function (data, status) {
                errorHandler(data, status);
            }
        });
    },
    callServiceSAP: function (url, data, successHandler, errorHandler) {

        var aData = jQuery.post({
            type: "POST",
            contentType: "application/json",
            crossDomain: true,
            dataType: 'json',
            url: url,
            data: data,
            async: false,
            success: function (data) {
                successHandler(data);
            },
            error: function (data, status) {
                errorHandler(data, status);
            }
        });
    },
    updateServiceSAP: function (url, data, successHandler, errorHandler) {
        var vJSON = JSON.stringify(data);
        var aData = jQuery.post({
            type: "POST",
            contentType: "application/json",
            crossDomain: true,
            dataType: 'json',
            url: url,
            data: vJSON,
            async: true,
            success: function (data) {
                successHandler(data);
            },
            error: function (data, status) {
                errorHandler(data, status);
            }
        });
    },

    readSAP: function (pSource, pParamsSAP, pController, successHandler, errorHandler) {

        switch (pController.getOwnerComponent().getMetadata().getConfig().custApp.typeReadModel) {
            case DC_TYPE_READ_MODEL_FILE: // JSON File
                this.callGetRestService(
                    pSource.file,
                    successHandler,
                    errorHandler
                );
                break;
            case DC_TYPE_READ_MODEL_HTTP: // HTTP JSON SAP
                // Construyo la URL que se llama a SAP
                var url = DC_URL_APP + pController.getOwnerComponent().getMetadata().getConfig().sap.path + "?LANGUAGE=" + language + "&EVENT=" + pSource.http;
                this.callServiceSAP(
                    url,
                    pParamsSAP,
                    successHandler,
                    errorHandler
                );
                break;
            case "3": // SAP GATEWAY

                /*
                 // al servicio de gateway se le concatena los parámetros especificos
                 var action = pSource.gateway.concat(pParamsGateway);

                 modelSAP.read(
                 action,
                 null,
                 null,
                 false,
                 function success(oData, response) {
                 successHandler(oData);
                 },
                 function error(oError) {
                 errorHandler(oError);
                 }
                 );
                 */
                break;
        }

    },

    updateSAP: function (pSource, pParamsSAP, pController, successHandler, errorHandler) {


        switch (pController.getOwnerComponent().getMetadata().getConfig().custApp.typeReadModel) {
            case DC_TYPE_READ_MODEL_FILE: // JSON File
                break;
            case DC_TYPE_READ_MODEL_HTTP: // HTTP JSON SAP
                // Construyo la URL que se llama a SAP
                var url = DC_URL_APP + pController.getOwnerComponent().getMetadata().getConfig().sap.path + "?LANGUAGE=" + language + "&EVENT=" + pSource.http;
                this.updateServiceSAP(
                    url,
                    pParamsSAP,
                    successHandler,
                    errorHandler
                );
                break;
        }

    },

    updateBatch: function (accept) {
        /*
         if(testMode){

         sap.ui.getCore().getModel().setProperty("/infoDialog", {
         "Text" : oBundle.getText("infoDialog.success"),
         "State" : sap.ui.core.ValueState.Success
         });
         sap.ui.jsfragment("fragment.InfoDialog").open();

         } else {

         var batchChanges = [];

         $.each(sap.ui.getCore().getModel().getProperty("/empleados"), function(index, item){

         var subty = sap.ui.getCore().getModel().getProperty("/unidadPresupuestariaSelected").Subty;
         var orgeh = item.Orgeh;
         var pernr = item.Pernr;

         //Update status
         if(accept){
         item.Cstat = STATE_TYPE.AUTORIZADO;
         } else {
         item.Cstat = STATE_TYPE.EN_PLANIFICACION;
         }

         batchChanges.push(
         modelSAPBatch.createBatchOperation(
         "/EMPLEADOS_UNIDADSet(Subty='" + subty + "',Orgeh='" + orgeh + "',Pernr='" + pernr + "')",
         "PUT",
         item
         )
         );
         });

         modelSAPBatch.addBatchChangeOperations(batchChanges);
         modelSAPBatch.setUseBatch(true);

         modelSAPBatch.submitBatch(
         function successHandler(oData){
         sap.ui.getCore().getModel().setProperty("/infoDialog", {
         "Text" : oBundle.getText("infoDialog.success"),
         "State" : sap.ui.core.ValueState.Success
         });
         sap.ui.jsfragment("fragment.InfoDialog").open();
         },
         function errorHandler(oData){
         RESTUtil.manageErrorResponse(data);
         }
         );
         } */
    },

    manageErrorResponse: function (oController, pTypeView, data, pDefaultText) {


        var resourceBundle = oController.getOwnerComponent().getModel("i18n").getResourceBundle();
        var text = this.getErrorResponse(data);

        // Si no hay text de error entonces le pongo el que viene por parámetro. En caso que no venga se le pone uno generico.
        if (!text || 0 === text.length) {
            if (!pDefaultText) {
                var resourceBundle = oController.getOwnerComponent().getModel("i18n").getResourceBundle();
                text = resourceBundle.getText("RESTUtil.genericError");
            }
            else {
                text = pDefaultText;
            }
        }

        // Paso el error al modelo para poderlo mostrar el las vistas de info
        oController.getOwnerComponent().getModel("infoDialog").setProperty("/Text", text);
        oController.getOwnerComponent().getModel("infoDialog").setProperty("/State", sap.ui.core.ValueState.Error);
        oController.getOwnerComponent().getModel("infoDialog").setProperty("/Title", resourceBundle.getText("dataModel.genericTitleError"));

        // Lanzo el tipo de vista a mostrar con el error. Es posible que no se quiera mostrar nada.
        switch (pTypeView) {
            case "V": // Vista
                oController.getOwnerComponent().getRouter().navTo("info");
                break;
            case "P": // POP UP
                oController.getOwnerComponent().infoDialog.open(oController.getView());
                break;
            case "N": // Nothing
                break;
        }

    },
    getErrorResponse: function (pData) {

        var text = "";

        try {
            //JSON.parse(pData.message).error.message.value;
            text = pData.message;
        } catch (err) {

        }
        return text;
    }
}
