using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor.UIElements;
using UnityEngine;
using UnityEngine.UIElements;

namespace UnityEditor.Rendering.LookDev
{   
    partial class DisplayWindow
    {
        static partial class Style
        {
            internal const string k_DebugViewLabel = "Selected View";
            internal const string k_DebugShadowLabel = "Display Shadows";
            internal const string k_DebugViewMode = "View Mode";

            internal static readonly Texture2D k_LockOpen = CoreEditorUtils.LoadIcon(Style.k_IconFolder, "Unlocked", forceLowRes: true);
            internal static readonly Texture2D k_LockClose = CoreEditorUtils.LoadIcon(Style.k_IconFolder, "Locked", forceLowRes: true);

            // /!\ WARNING:
            //The following const are used in the uss.
            //If you change them, update the uss file too.
            internal const string k_DebugToolbarLineName = "debugToolbarLine";
            internal const string k_DebugToolbarName = "debugToolbar";
            internal const string k_Lock = "lock";

        }

        bool cameraSynced
            => LookDev.currentContext.cameraSynced;

        ViewContext lastFocusedViewContext
            => LookDev.currentContext.GetViewContent(LookDev.currentContext.layout.lastFocusedView);
        
        void ApplyFilteredViewsContext(Action<ViewContext> action)
        {
            if (debugView1SidePanel)
                action?.Invoke(LookDev.currentContext.GetViewContent(ViewIndex.First));
            if (debugView2SidePanel)
                action?.Invoke(LookDev.currentContext.GetViewContent(ViewIndex.Second));
        }

        void CreateDebug()
        {
            if (m_MainContainer == null || m_MainContainer.Equals(null))
                throw new System.MemberAccessException("m_MainContainer should be assigned prior CreateEnvironment()");

            m_DebugContainer = new VisualElement() { name = Style.k_DebugContainerName };
            m_MainContainer.Add(m_DebugContainer);
            if (debugOneOfViewSidePanel)
                m_MainContainer.AddToClassList(Style.k_ShowDebugPanelClass);
            
            AddDebugShadow();

            //[TODO: finish]
            //Toggle greyBalls = new Toggle("Grey balls");
            //greyBalls.SetValueWithoutNotify(LookDev.currentContext.GetViewContent(LookDev.currentContext.layout.lastFocusedView).debug.greyBalls);
            //greyBalls.RegisterValueChangedCallback(evt =>
            //{
            //    LookDev.currentContext.GetViewContent(LookDev.currentContext.layout.lastFocusedView).debug.greyBalls = evt.newValue;
            //});
            //m_DebugContainer.Add(greyBalls);

            //[TODO: debug why list sometimes empty on resource reloading]
            //[TODO: display only per view]

            AddDebugViewMode();
        }
        
        void AddDebugShadow()
        {
            Toggle shadow = new Toggle(Style.k_DebugShadowLabel);
            shadow.value = lastFocusedViewContext.debug.shadow;
            shadow.RegisterValueChangedCallback(evt
                => ApplyFilteredViewsContext(view => view.debug.shadow = evt.newValue));
            m_DebugContainer.Add(shadow);
        }

        void AddDebugViewMode()
        {
            if (m_DebugView != null && m_DebugContainer.Contains(m_DebugView))
                m_DebugContainer.Remove(m_DebugView);

            List<string> list = new List<string>(LookDev.dataProvider?.supportedDebugModes ?? Enumerable.Empty<string>());
            list.Insert(0, "None");
            m_DebugView = new PopupField<string>(Style.k_DebugViewMode, list, 0);
            m_DebugView.RegisterValueChangedCallback(evt
                => LookDev.dataProvider.UpdateDebugMode(list.IndexOf(evt.newValue) - 1));
            m_DebugContainer.Add(m_DebugView);
        }
        
    }
}
