import React from 'react';
import { Link } from 'react-router-dom';
import {
  Bot,
  FileSpreadsheet,
  Coins,
  Rocket,
  BarChart3,
  Library,
  Plus,
  Lightbulb,
  ArrowRight,
  Sparkles
} from 'lucide-react';

export default function IdeaHub() {
  const tools = [
    {
      icon: Lightbulb,
      title: 'Idea Refinement',
      description: 'Get AI feedback on your startup ideas and explore variations.',
      action: {
        text: 'Refine Idea',
        href: '/idea-hub/refinement'
      }
    },
    {
      icon: BarChart3,
      title: 'Market Validation',
      description: 'Validate your market assumptions and identify opportunities.',
      action: {
        text: 'Validate Market',
        href: '/idea-hub/market-validation'
      }
    },
    {
      icon: Coins,
      title: 'Business Model',
      description: 'Define your revenue streams and cost structure.',
      action: {
        text: 'Build Model',
        href: '/idea-hub/business-model'
      }
    },
    {
      icon: Rocket,
      title: 'AI Pitch Deck Generator',
      description: 'Create professional investor-ready pitch decks with AI.',
      isNew: true,
      action: {
        text: 'Create Deck',
        href: '/idea-hub/pitch-deck'
      }
    },
    {
      icon: Bot,
      title: 'AI Discussion',
      description: 'Discuss your ideas with our AI co-founder.',
      action: {
        text: 'Start Discussion',
        href: '/idea-hub/ai-discussion'
      }
    },
    {
      icon: FileSpreadsheet,
      title: 'Idea Canvas',
      description: 'Structure and visualize your business concept.',
      action: {
        text: 'Open Canvas',
        href: '/idea-hub/canvas'
      }
    }
  ];

  return (
    <div className="py-6">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">Idea Hub</h1>
            <p className="mt-1 text-sm text-gray-500">
              Transform your ideas into successful startups
            </p>
          </div>
          <Link
            to="/idea-hub/refinement"
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700"
          >
            <Plus className="h-4 w-4 mr-2" />
            New Idea
          </Link>
        </div>

        {/* Featured Tool */}
        <div className="mb-8 bg-gradient-to-r from-indigo-500 to-purple-600 rounded-lg shadow-lg overflow-hidden">
          <div className="px-6 py-8 sm:p-10">
            <div className="sm:flex sm:items-start sm:justify-between">
              <div className="sm:flex-1">
                <h2 className="text-xl font-semibold text-white sm:text-2xl">
                  New: AI-Powered Pitch Deck Generator
                </h2>
                <p className="mt-2 text-sm text-indigo-100 sm:text-base">
                  Create professional investor-ready pitch decks in minutes. Our AI analyzes your business 
                  and generates compelling slides with persuasive content tailored to your startup.
                </p>
                <div className="mt-4 sm:mt-6">
                  <Link
                    to="/idea-hub/pitch-deck"
                    className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-indigo-600 bg-white hover:bg-indigo-50"
                  >
                    <Sparkles className="mr-2 h-5 w-5" />
                    Try AI Pitch Deck Generator
                    <ArrowRight className="ml-2 h-5 w-5" />
                  </Link>
                </div>
              </div>
              <div className="mt-4 sm:mt-0 sm:ml-6">
                <div className="bg-white/10 p-4 rounded-lg">
                  <Rocket className="h-16 w-16 text-white" />
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Tools Grid */}
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {tools.map((tool) => (
            <div
              key={tool.title}
              className="relative bg-white rounded-lg shadow-sm overflow-hidden border border-gray-200"
            >
              {tool.isNew && (
                <div className="absolute top-4 right-4">
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
                    <Sparkles className="h-3 w-3 mr-1" />
                    New
                  </span>
                </div>
              )}
              <div className="p-6">
                <div className="flex justify-center items-center w-12 h-12 rounded-full bg-indigo-100 text-indigo-600 mb-4">
                  <tool.icon className="h-6 w-6" />
                </div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">{tool.title}</h3>
                <p className="text-sm text-gray-500 mb-4 h-12">{tool.description}</p>
                <Link
                  to={tool.action.href}
                  className="inline-flex items-center text-sm font-medium text-indigo-600 hover:text-indigo-500"
                >
                  {tool.action.text}
                  <ArrowRight className="ml-1 h-4 w-4" />
                </Link>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}