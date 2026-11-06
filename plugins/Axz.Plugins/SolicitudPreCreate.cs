using System;
using Microsoft.Xrm.Sdk;

namespace Axz.Plugins
{
    /// <summary>
    /// PreOperation / Create sobre axz_solicitud.
    /// Genera el correlation ID y deja la solicitud en estado Pendiente.
    /// </summary>
    public class SolicitudPreCreate : IPlugin
    {
        private const int EstadoPendiente = 100000000; // sustituir por el valor real de la choice

        public void Execute(IServiceProvider serviceProvider)
        {
            var context = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));
            var trace = (ITracingService)serviceProvider.GetService(typeof(ITracingService));

            var target = context.InputParameters["Target"] as Entity;
            
            target.Attributes["axz_nombre"] = target.Attributes["axz_nombre"] + DateTime.Now.ToString();
        }
    }
}
