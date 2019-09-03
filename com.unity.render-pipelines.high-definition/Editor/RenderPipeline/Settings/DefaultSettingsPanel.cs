using System;
using System.Collections.Generic;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Rendering;
using UnityEngine.UIElements;
using UnityEditorInternal;

namespace UnityEditor.Rendering.HighDefinition
{
    class DefaultSettingsPanelProvider
    {
        [SettingsProvider]
        public static SettingsProvider CreateSettingsProvider()
        {
            return new SettingsProvider("Project/HDRP Default Settings", SettingsScope.Project)
            {
                activateHandler = (searchContext, rootElement) =>
                {
                    HDEditorUtils.AddStyleSheets(rootElement, HDEditorUtils.FormatingPath);
                    HDEditorUtils.AddStyleSheets(rootElement, HDEditorUtils.QualitySettingsSheetPath);

                    var panel = new DefaultSettingsPanel(searchContext);
                    panel.style.flexGrow = 1;

                    rootElement.Add(panel);
                },
                keywords = new [] { "default", "hdrp" }
            };
        }

        class DefaultSettingsPanel : VisualElement
        {
            VolumeComponentListEditor m_ComponentList;
            Editor m_Cached;

            ReorderableList m_BeforeTransparentCustomPostProcesses;
            ReorderableList m_BeforePostProcessCustomPostProcesses;
            ReorderableList m_AfterPostProcessCustomPostProcesses;

            public DefaultSettingsPanel(string searchContext)
            {
                var scrollView = new ScrollView();
                {
                    var title = new Label
                    {
                        text = "General Settings"
                    };
                    title.AddToClassList("h1");
                    scrollView.contentContainer.Add(title);
                }
                {
                    var generalSettingsInspector = new IMGUIContainer(Draw_GeneralSettings);
                    generalSettingsInspector.style.marginLeft = 5;
                    scrollView.contentContainer.Add(generalSettingsInspector);
                }
                {
                    var space = new VisualElement();
                    space.style.height = 10;
                    scrollView.contentContainer.Add(space);
                }
                {
                    var title = new Label
                    {
                        text = "Frame Settings"
                    };
                    title.AddToClassList("h1");
                    scrollView.contentContainer.Add(title);
                }
                {
                    var generalSettingsInspector = new IMGUIContainer(Draw_DefaultFrameSettings);
                    generalSettingsInspector.style.marginLeft = 5;
                    scrollView.contentContainer.Add(generalSettingsInspector);
                }
                {
                    var space = new VisualElement();
                    space.style.height = 10;
                    scrollView.contentContainer.Add(space);
                }
                {
                    var title = new Label
                    {
                        text = "Volume Components"
                    };
                    title.AddToClassList("h1");
                    scrollView.contentContainer.Add(title);
                }
                {
                    var volumeInspector = new IMGUIContainer(Draw_VolumeInspector);
                    volumeInspector.style.flexGrow = 1;
                    volumeInspector.style.flexDirection = FlexDirection.Row;
                    scrollView.contentContainer.Add(volumeInspector);
                }
                {
                    var title = new Label
                    {
                        text = "Custom Post Process Orders"
                    };
                    title.AddToClassList("h1");
                    scrollView.contentContainer.Add(title);
                }

                InitializeCustomPostProcessesLists();

                {
                    var volumeInspector = new IMGUIContainer(Draw_CustomPostProcess);
                    volumeInspector.style.flexGrow = 1;
                    volumeInspector.style.flexDirection = FlexDirection.Row;
                    scrollView.contentContainer.Add(volumeInspector);
                }

                Add(scrollView);
            }

            private static GUIContent k_DefaultHDRPAsset = new GUIContent("Asset with the default settings");
            void Draw_GeneralSettings()
            {
                var hdrpAsset = HDRenderPipeline.defaultAsset;
                if (hdrpAsset == null)
                {
                    EditorGUILayout.HelpBox("Base SRP Asset is not an HDRenderPipelineAsset.", MessageType.Warning);
                    return;
                }

                GUI.enabled = false;
                EditorGUILayout.ObjectField(k_DefaultHDRPAsset, hdrpAsset, typeof(HDRenderPipelineAsset), false);
                GUI.enabled = true;

                var serializedObject = new SerializedObject(hdrpAsset);
                var serializedHDRPAsset = new SerializedHDRenderPipelineAsset(serializedObject);

                HDRenderPipelineUI.GeneralSection.Draw(serializedHDRPAsset, null);

                serializedObject.ApplyModifiedProperties();
            }

            private static GUIContent k_DefaultVolumeProfileLabel = new GUIContent("Default Volume Profile Asset");
            void Draw_VolumeInspector()
            {
                var hdrpAsset = HDRenderPipeline.defaultAsset;
                if (hdrpAsset == null)
                    return;

                var asset = EditorDefaultSettings.GetOrAssignDefaultVolumeProfile();

                var newAsset = (VolumeProfile)EditorGUILayout.ObjectField(k_DefaultVolumeProfileLabel, asset, typeof(VolumeProfile), false);
                if (newAsset != null && newAsset != asset)
                {
                    asset = newAsset;
                    hdrpAsset.defaultVolumeProfile = asset;
                    EditorUtility.SetDirty(hdrpAsset);
                }

                Editor.CreateCachedEditor(asset,
                    Type.GetType("UnityEditor.Rendering.VolumeProfileEditor"), ref m_Cached);
                m_Cached.OnInspectorGUI();
            }

            void Draw_DefaultFrameSettings()
            {
                var hdrpAsset = HDRenderPipeline.defaultAsset;
                if (hdrpAsset == null)
                    return;

                var serializedObject = new SerializedObject(hdrpAsset);
                var serializedHDRPAsset = new SerializedHDRenderPipelineAsset(serializedObject);

                HDRenderPipelineUI.FrameSettingsSection.Draw(serializedHDRPAsset, null);
                serializedObject.ApplyModifiedProperties();
            }

            void InitializeCustomPostProcessesLists()
            {
                var hdrpAsset = HDRenderPipeline.defaultAsset;
                if (hdrpAsset == null)
                    return;

                InitList(ref m_BeforeTransparentCustomPostProcesses, hdrpAsset.beforeTransparentCustomPostProcesses, "Before Transparent");
                InitList(ref m_BeforePostProcessCustomPostProcesses, hdrpAsset.beforePostProcessCustomPostProcesses, "Before Post Process");
                InitList(ref m_AfterPostProcessCustomPostProcesses, hdrpAsset.afterPostProcessCustomPostProcesses, "After Post Process");

                void InitList(ref ReorderableList reorderableList, List<Type> customPostProcessTypes, string headerName)
                {
                    reorderableList = new ReorderableList(customPostProcessTypes, typeof(Type));
                    reorderableList.drawHeaderCallback = (rect) =>
                        EditorGUI.LabelField(rect, headerName, EditorStyles.boldLabel);
                    reorderableList.drawElementCallback = (rect, index, isActive, isFocused) =>
                    {
                        var elem = customPostProcessTypes[index];
                        Rect positionRect = rect;
                        rect.width = 20;
                        rect.x += 20;
                        EditorGUI.LabelField(positionRect, index.ToString());
                        EditorGUI.LabelField(rect, elem.ToString());
                    };
                    reorderableList.onAddCallback = (list) =>
                    {
                        var menu = new GenericMenu();

                        // TODO: fill the context menu

                        menu.ShowAsContext();
                    };
                    reorderableList.elementHeightCallback = _ => EditorGUIUtility.singleLineHeight;
                }
            }

            void Draw_CustomPostProcess()
            {
                m_BeforeTransparentCustomPostProcesses.DoLayoutList();
                m_BeforePostProcessCustomPostProcesses.DoLayoutList();
                m_AfterPostProcessCustomPostProcesses.DoLayoutList();
            }
        }
    }
}
