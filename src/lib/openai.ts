import OpenAI from 'openai';
import { supabase } from './supabase';

// Mock responses for all OpenAI calls
const MOCK_RESPONSES = {
  tasks: {
    feedback: {
      strengths: [
        "Clear focus on key deliverables",
        "Good progress on core features",
        "Proactive problem identification"
      ],
      areas_for_improvement: [
        "Consider breaking down larger tasks",
        "Document technical decisions"
      ],
      opportunities: [
        "Potential for automation",
        "Integration possibilities"
      ],
      risks: [
        "Technical debt accumulation",
        "Resource constraints"
      ],
      strategic_recommendations: [
        "Implement automated testing",
        "Create technical documentation",
        "Review architecture decisions"
      ]
    },
    follow_up_questions: [
      "Have you considered alternative approaches?",
      "What metrics will you use to measure success?",
      "Are there any dependencies to consider?"
    ],
    tasks: [
      {
        title: "Implement Core Feature",
        description: "Build the main functionality based on requirements",
        priority: "high",
        estimated_hours: 8,
        task_type: "Feature Development",
        implementation_tips: [
          "Start with basic functionality",
          "Add error handling",
          "Include unit tests"
        ],
        potential_challenges: [
          "Complex edge cases",
          "Performance considerations",
          "Integration points"
        ],
        success_metrics: [
          "All tests passing",
          "Performance benchmarks met",
          "Code review approved"
        ],
        resources: [
          {
            title: "Best Practices Guide",
            url: "https://example.com/guide",
            type: "article",
            description: "Comprehensive guide for implementation"
          }
        ],
        learning_resources: [
          {
            title: "Advanced Techniques",
            url: "https://example.com/course",
            type: "course",
            platform: "Learning Platform",
            description: "In-depth course on implementation"
          }
        ],
        tools: [
          {
            name: "Development Tool",
            url: "https://example.com/tool",
            category: "Development",
            description: "Essential tool for implementation"
          }
        ]
      }
    ]
  },
  market_analysis: {
    customer_profiles: [
      {
        segment: "Early Adopters",
        description: "Tech-savvy professionals aged 25-40",
        needs: ["Efficiency", "Innovation", "Cost savings"],
        pain_points: ["Time-consuming processes", "Manual work"],
        buying_behavior: "Research-driven, willing to try new solutions",
        sources: [
          {
            name: "Market Research Report 2025",
            url: "https://example.com/report",
            type: "research_report",
            year: 2025
          }
        ]
      }
    ],
    early_adopters: [
      {
        type: "Tech Startups",
        characteristics: ["Innovation-focused", "Quick to adopt", "Value-driven"],
        acquisition_strategy: "Direct outreach and community engagement",
        sources: [
          {
            name: "Startup Ecosystem Report",
            url: "https://example.com/startup-report",
            type: "market_research",
            year: 2025
          }
        ]
      }
    ],
    sales_channels: [
      {
        channel: "Direct Sales",
        effectiveness: 0.8,
        cost: "High initial investment",
        timeline: "3-6 months",
        sources: [
          {
            name: "Sales Strategy Analysis",
            url: "https://example.com/sales",
            type: "industry_report",
            year: 2025
          }
        ]
      }
    ],
    pricing_insights: [
      {
        model: "Tiered Subscription",
        price_point: "$49-299/month",
        justification: "Aligned with market expectations and value delivery",
        sources: [
          {
            name: "Pricing Study 2025",
            url: "https://example.com/pricing",
            type: "market_research",
            year: 2025
          }
        ]
      }
    ],
    market_size: {
      tam: "$50B annually",
      sam: "$10B annually",
      som: "$500M annually",
      growth_rate: "15% YoY",
      sources: [
        {
          name: "Industry Analysis",
          url: "https://example.com/analysis",
          type: "market_report",
          year: 2025
        }
      ]
    }
  },
  market_suggestions: {
    target_audience: [
      "Small Business Owners",
      "Startup Founders", 
      "Enterprise Companies",
      "Digital Agencies",
      "E-commerce Businesses"
    ],
    sales_channels: [
      "Direct Sales",
      "Online Platform",
      "Partner Network",
      "Resellers",
      "Marketplaces"
    ],
    pricing_model: [
      "Subscription",
      "Usage-based",
      "Freemium",
      "Enterprise",
      "Marketplace Fee"
    ],
    customer_type: [
      "B2B",
      "Enterprise",
      "SMB",
      "Startups",
      "Agencies"
    ],
    integration_needs: [
      "CRM Systems",
      "Payment Processors",
      "Communication Tools",
      "Analytics Platforms",
      "Project Management"
    ]
  },
  idea_variations: [
    {
      id: "1",
      title: "Premium SaaS Solution",
      description: "Enterprise-grade software with advanced features",
      differentiator: "AI-powered automation and analytics",
      targetMarket: "Large enterprises",
      revenueModel: "Annual subscription with tiered pricing"
    },
    {
      id: "2",
      title: "Freemium Model",
      description: "Basic features free, premium features paid",
      differentiator: "Easy onboarding and scalability",
      targetMarket: "Small businesses and startups",
      revenueModel: "Freemium with premium tiers"
    },
    {
      id: "3",
      title: "Marketplace Platform",
      description: "Two-sided marketplace connecting providers and users",
      differentiator: "Network effects and commission model",
      targetMarket: "Service providers and consumers",
      revenueModel: "Transaction fees and subscriptions"
    }
  ],
  combined_ideas: [
    {
      id: "1",
      title: "Enterprise + Freemium Hybrid",
      description: "Combined solution offering both enterprise and SMB features",
      sourceElements: [
        "AI-powered automation",
        "Easy onboarding",
        "Tiered pricing"
      ],
      targetMarket: "All business sizes",
      revenueModel: "Hybrid subscription model",
      valueProposition: "Scalable solution for growing businesses"
    },
    {
      id: "2",
      title: "Marketplace + Enterprise Services",
      description: "Marketplace platform with enterprise integration capabilities",
      sourceElements: [
        "Network effects",
        "Advanced features",
        "Service integration"
      ],
      targetMarket: "Enterprise and service providers",
      revenueModel: "Mixed revenue streams",
      valueProposition: "End-to-end solution platform"
    }
  ]
};

// Generate AI feedback and tasks
export const generateTasks = async (entry: {
  accomplished: string;
  working_on: string;
  blockers: string;
  goals: string;
}, userId: string) => {
  try {
    return {
      feedback: MOCK_RESPONSES.tasks.feedback,
      follow_up_questions: MOCK_RESPONSES.tasks.follow_up_questions,
      tasks: MOCK_RESPONSES.tasks.tasks
    };
  } catch (error: any) {
    console.error('Error generating tasks:', error);
    throw new Error(error.message || 'Failed to generate tasks');
  }
};

// Generate market analysis
export const generateMarketAnalysis = async (idea: any) => {
  try {
    return MOCK_RESPONSES.market_analysis;
  } catch (error: any) {
    console.error('Error generating market analysis:', error);
    throw new Error(error.message || 'Failed to generate market analysis');
  }
};

// Generate market suggestions
export const generateMarketSuggestions = async (idea: any) => {
  try {
    return MOCK_RESPONSES.market_suggestions;
  } catch (error: any) {
    console.error('Error generating market suggestions:', error);
    throw new Error(error.message || 'Failed to generate market suggestions');
  }
};

// Generate idea variations
export const generateIdeaVariations = async (idea: any) => {
  try {
    return MOCK_RESPONSES.idea_variations.map(v => ({
      ...v,
      isSelected: false,
      isEditing: false
    }));
  } catch (error: any) {
    console.error('Error generating idea variations:', error);
    throw new Error(error.message || 'Failed to generate idea variations');
  }
};

// Generate combined ideas
export const generateCombinedIdeas = async (baseIdea: string, selectedVariations: any[]) => {
  try {
    return MOCK_RESPONSES.combined_ideas.map(idea => ({
      ...idea,
      isSelected: false,
      isEditing: false
    }));
  } catch (error: any) {
    console.error('Error generating combined ideas:', error);
    throw new Error(error.message || 'Failed to generate combined ideas');
  }
};