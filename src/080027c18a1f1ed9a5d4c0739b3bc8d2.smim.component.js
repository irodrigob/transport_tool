var errorDataModel = false;

sap.ui.define([
    "sap/ui/core/UIComponent",
    "sap/ui/model/json/JSONModel",
    "sap/ui/model/resource/ResourceModel",
    "sap/m/MessageToast",
    "com/irb/trans/controller/infoDialog",
    "sap/ui/Device"
], function (UIComponent, JSONModel, ResourceModel,MessageToast,infoDialog,Device) {
    "use strict";
    return UIComponent.extend("com.irb.trans.Component", {
        metadata: {
            manifest: "json"
        },

        init: function () {

            // set i18n model
            /*var i18nModel = new ResourceModel({
                bundleName: "com.irb.trans.i18n.i18n"
            });
            this.setModel(i18nModel, "i18n");


            // Recupero del modelo i18n el texto de la aplicación para ponerselo a la ventana
            var oResourceBundle = this.getModel("i18n").getResourceBundle();
            document.title = oResourceBundle.getText("appTitle"); */

            // Inicializacion modelo datos
            this.initModelData();

            // Idioma del navegador
            var sCurrentLocale = sap.ui.getCore().getConfiguration().getLanguage().substring(0, 2).toUpperCase();
            this.getModel().setProperty("/Spras", sCurrentLocale);

            // Asocio el fragmento de ventana de dialogos para que cualquier vista pueda usarla
            this.infoDialog = new infoDialog();

            // La llamada al componente padre se tiene que hacer al final porque cuando se hace se llama a los init de las vistas. Esto
            // hace que algunas cosas no esten inicializadas y fallen
            UIComponent.prototype.init.apply(this, arguments);

            // Inicializamos la ruta
            this.getRouter().initialize();

            // Una vez se han cargado las vistas si hay hay algún error, muestro el mensaje error que se haya producido
            if (this.getModel().getProperty("/errorApp")){
                MessageToast.show(this.getModel("infoDialog").getProperty("/Text"), {autoClose:false, duration: 6000, width:"30em"});
            }

        },
        initModelData: function () {


            //Inicializamos un modelo generico para jugar con las propiedades que me permitiran hacer control de errores
            // y similares
            var globalModel = new sap.ui.model.json.JSONModel();
            globalModel.setData({});
            this.setModel(globalModel);


            // Creo el modelo que se usara para mostrar datos en el fragmento y vista de dialogos. De esta manera después
            // es mas sencillo actualizar datos que ir creando el modelo cada vez
            var oInfoDialog = new sap.ui.model.json.JSONModel({
                "Text" : "",
                "Description":"",
                "State" : "",
                "Title": ""});
            this.setModel(oInfoDialog, "infoDialog");

            // Si el modelo se va a recuperar de Gateway paso al modelo la ruta donde tiene que obtenerlo
         /*   if (this.getMetadata().getConfig().custApp.typeReadModel === "3"){
                dataModel.modelSAPSet(this.getMetadata().getConfig().gateway.modelHost);
            } */
        },
        /**
         * This method can be called to determine whether the sapUiSizeCompact or sapUiSizeCozy
         * design mode class should be set, which influences the size appearance of some controls.
         * @public
         * @return {string} css class, either 'sapUiSizeCompact' or 'sapUiSizeCozy' - or an empty string if no css class should be set
         */
        getContentDensityClass : function() {
            if (this._sContentDensityClass === undefined) {
                // check whether FLP has already set the content density class; do nothing in this case
                if (jQuery(document.body).hasClass("sapUiSizeCozy") || jQuery(document.body).hasClass("sapUiSizeCompact")) {
                    this._sContentDensityClass = "";
                } else if (!Device.support.touch) { // apply "compact" mode if touch is not supported
                    this._sContentDensityClass = "sapUiSizeCompact";
                } else {
                    // "cozy" in case of touch support; default for most sap.m controls, but needed for desktop-first controls like sap.ui.table.Table
                    this._sContentDensityClass = "sapUiSizeCozy";
                }
            }
            return this._sContentDensityClass;
        }
    });
});

